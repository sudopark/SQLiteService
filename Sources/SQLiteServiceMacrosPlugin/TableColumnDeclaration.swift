//
//  TableColumnDeclaration.swift
//
//
//  Created by sudo.park.
//

import Foundation
import SwiftSyntax


// MARK: - TableColumnDeclaration

struct TableColumnDeclaration {

    let propertyName: String
    let columnName: String
    let columnNameLiteral: String
    let typeDescription: String
    let isOptional: Bool
    let dataTypeCaseName: String
    let attributeExpressions: [String]

    var attributeArrayLiteral: String {
        return "[\(self.attributeExpressions.joined(separator: ", "))]"
    }

    var caseDeclaration: String {
        return self.propertyName.withoutBackticks == self.columnName
            ? "case \(self.propertyName)"
            : "case \(self.propertyName) = \(self.columnNameLiteral)"
    }

    /// Mutability follows the column type, not how the table declared it - an optional column
    /// is mutable and defaults to nil, so an entity can be built without it and filled in later.
    var entityPropertyDeclaration: String {
        let specifier = self.isOptional ? "var" : "let"
        return "\(specifier) \(self.propertyName): \(self.typeDescription)"
    }

    var initParameterDeclaration: String {
        let defaultValue = self.isOptional ? " = nil" : ""
        return "\(self.propertyName): \(self.typeDescription)\(defaultValue)"
    }

    var cursorReadExpression: String {
        return self.isOptional ? "cursor.next()" : "try cursor.next().unwrap()"
    }
}


// MARK: - parse column declarations

extension StructDeclSyntax {

    func parseTableColumnDeclarations() throws -> [TableColumnDeclaration] {
        return try self.memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .filter { $0.isInstanceProperty }
            .flatMap { try $0.asTableColumnDeclarations() }
    }
}

private extension VariableDeclSyntax {

    var isInstanceProperty: Bool {
        return self.modifiers.contains {
            $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
        } == false
    }

    func asTableColumnDeclarations() throws -> [TableColumnDeclaration] {
        let columnAttribute = self.attributes
            .compactMap { $0.as(AttributeSyntax.self) }
            .first { $0.attributeName.trimmedDescription == "Column" }
        let arguments = try columnAttribute?.columnArguments() ?? (attributes: [], name: nil)

        return try self.bindings.typeAnnotatedPairs.map { binding, type in
            let propertyName = binding.pattern.trimmedDescription
            guard binding.accessorBlock == nil else {
                throw TableMacroError.accessorIsNotAllowed(propertyName)
            }
            guard let type = type else {
                throw TableMacroError.missingTypeAnnotation(propertyName)
            }
            let (baseType, isOptional) = type.unwrappedOptional
            guard let caseName = baseType.columnDataTypeCaseName else {
                throw TableMacroError.unsupportedColumnType(
                    property: propertyName, type: baseType.trimmedDescription
                )
            }
            return TableColumnDeclaration(
                propertyName: propertyName,
                columnName: arguments.name?.value ?? propertyName.withoutBackticks,
                columnNameLiteral: arguments.name?.literal ?? propertyName.withoutBackticks.asStringLiteral,
                typeDescription: type.trimmedDescription,
                isOptional: isOptional,
                dataTypeCaseName: caseName,
                attributeExpressions: arguments.attributes
            )
        }
    }
}

private extension PatternBindingListSyntax {

    /// `var a, b: String` annotates only the last binding, the preceding ones share it.
    var typeAnnotatedPairs: [(PatternBindingSyntax, TypeSyntax?)] {
        var followingType: TypeSyntax?
        return self.reversed().map { binding -> (PatternBindingSyntax, TypeSyntax?) in
            followingType = binding.typeAnnotation?.type ?? followingType
            return (binding, followingType)
        }.reversed()
    }
}

private extension AttributeSyntax {

    func columnArguments() throws -> (attributes: [String], name: StringLiteral?) {
        guard case let .argumentList(list) = self.arguments else { return ([], nil) }
        let attributes = list.filter { $0.label == nil }.map { $0.expression.trimmedDescription }
        guard let nameArgument = list.first(where: { $0.label?.text == "name" })?.expression
        else { return (attributes, nil) }
        guard let name = nameArgument.asStringLiteral else {
            throw TableMacroError.columnNameIsNotLiteral(nameArgument.trimmedDescription)
        }
        return (attributes, name)
    }
}


// MARK: - type mapping

private extension TypeSyntax {

    var unwrappedOptional: (TypeSyntax, Bool) {
        if let optional = self.as(OptionalTypeSyntax.self) {
            return (optional.wrappedType, true)
        }
        if let identifier = self.as(IdentifierTypeSyntax.self),
           identifier.name.text == "Optional",
           let wrapped = identifier.genericArgumentClause?.arguments.first?.argument.as(TypeSyntax.self) {
            return (wrapped, true)
        }
        return (self, false)
    }

    var columnDataTypeCaseName: String? {
        guard let identifier = self.as(IdentifierTypeSyntax.self) else { return nil }
        switch identifier.name.text {
        case "Int", "Bool": return "integer"
        case "String": return "text"
        case "Double", "Float": return "real"
        default: return nil
        }
    }
}


// MARK: - string literal helpers

/// Keeps the literal as written so that quotes and escapes survive re-emission,
/// alongside the value the generated code has to compare and store.
struct StringLiteral {

    let value: String
    let literal: String
}

extension ExprSyntax {

    var asStringLiteral: StringLiteral? {
        guard let literal = self.as(StringLiteralExprSyntax.self),
              let value = literal.representedLiteralValue
        else { return nil }
        return .init(value: value, literal: literal.trimmedDescription)
    }
}

extension String {

    var withoutBackticks: String {
        return self.replacingOccurrences(of: "`", with: "")
    }

    var asStringLiteral: String {
        let escaped = self
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}
