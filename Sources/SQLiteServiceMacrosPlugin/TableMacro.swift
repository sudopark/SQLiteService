//
//  TableMacro.swift
//
//
//  Created by sudo.park.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


public struct TableMacro { }


// MARK: - TableMacro + MemberMacro

extension TableMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw TableMacroError.notAStruct
        }
        guard let tableNameLiteral = node.tableNameArgument?.literal else {
            throw TableMacroError.missingTableName
        }
        let columns = try structDecl.parseTableColumnDeclarations()
        guard columns.isEmpty == false else {
            throw TableMacroError.noColumnDeclared
        }

        let access = structDecl.generatedMemberAccessPrefix
        return [
            self.columnsEnumDeclaration(columns, access),
            self.entityStructDeclaration(columns, access),
            "\(raw: access)typealias ColumnType = Columns",
            "\(raw: access)typealias EntityType = Entity",
            "\(raw: access)static var tableName: String { \(raw: tableNameLiteral) }",
            self.scalarFunctionDeclaration(columns, access)
        ]
    }

    private static func columnsEnumDeclaration(
        _ columns: [TableColumnDeclaration], _ access: String
    ) -> DeclSyntax {
        let cases = columns.map { $0.caseDeclaration }.joined(separator: "\n")
        let dataTypeCases = columns
            .map { "case .\($0.propertyName): return .\($0.dataTypeCaseName)(\($0.attributeArrayLiteral))" }
            .joined(separator: "\n")
        return """
        \(raw: access)enum Columns: String, TableColumn {
        \(raw: cases)

        \(raw: access)var dataType: ColumnDataType {
        switch self {
        \(raw: dataTypeCases)
        }
        }
        }
        """
    }

    private static func entityStructDeclaration(
        _ columns: [TableColumnDeclaration], _ access: String
    ) -> DeclSyntax {
        let properties = columns
            .map { "\(access)\($0.entityPropertyDeclaration)" }
            .joined(separator: "\n")
        let initParameters = columns
            .map { $0.initParameterDeclaration }
            .joined(separator: ", ")
        let initAssignments = columns
            .map { "self.\($0.propertyName) = \($0.propertyName)" }
            .joined(separator: "\n")
        let cursorAssignments = columns
            .map { "self.\($0.propertyName) = \($0.cursorReadExpression)" }
            .joined(separator: "\n")
        return """
        \(raw: access)struct Entity: RowValueType {
        \(raw: properties)

        \(raw: access)init(\(raw: initParameters)) {
        \(raw: initAssignments)
        }

        \(raw: access)init(_ cursor: CursorIterator) throws {
        \(raw: cursorAssignments)
        }
        }
        """
    }

    private static func scalarFunctionDeclaration(
        _ columns: [TableColumnDeclaration], _ access: String
    ) -> DeclSyntax {
        let cases = columns
            .map { "case .\($0.propertyName): return entity.\($0.propertyName)" }
            .joined(separator: "\n")
        return """
        \(raw: access)static func scalar(_ entity: Entity, for column: Columns) -> ScalarType? {
        switch column {
        \(raw: cases)
        }
        }
        """
    }
}


// MARK: - TableMacro + ExtensionMacro

extension TableMacro: ExtensionMacro {

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.alreadyDeclaresTableConformance == false,
              declaration.isExpandableTableDeclaration
        else { return [] }
        let extensionDecl: DeclSyntax = "extension \(type.trimmed): Table { }"
        return extensionDecl.as(ExtensionDeclSyntax.self).map { [$0] } ?? []
    }
}


// MARK: - declaration helpers

private extension AttributeSyntax {

    var tableNameArgument: StringLiteral? {
        guard case let .argumentList(list) = self.arguments else { return nil }
        return list.first?.expression.asStringLiteral
    }
}

private extension DeclGroupSyntax {

    /// A failed member expansion already diagnosed the reason - adding a bare conformance
    /// here would bury it under missing requirement errors.
    var isExpandableTableDeclaration: Bool {
        guard let structDecl = self.as(StructDeclSyntax.self),
              let columns = try? structDecl.parseTableColumnDeclarations()
        else { return false }
        return columns.isEmpty == false
    }

    var alreadyDeclaresTableConformance: Bool {
        let inheritedTypes = self.inheritanceClause?.inheritedTypes ?? []
        return inheritedTypes.contains { $0.type.trimmedDescription == "Table" }
    }
}

private extension StructDeclSyntax {

    var generatedMemberAccessPrefix: String {
        let keywords: [TokenKind] = [.keyword(.public), .keyword(.package)]
        guard let modifier = self.modifiers.first(where: { keywords.contains($0.name.tokenKind) })
        else { return "" }
        return "\(modifier.name.text) "
    }
}
