//
//  TableMacroError.swift
//
//
//  Created by sudo.park.
//

import Foundation


enum TableMacroError: Error, CustomStringConvertible {

    case notAStruct
    case missingTableName
    case noColumnDeclared
    case missingTypeAnnotation(_ property: String)
    case unsupportedColumnType(property: String, type: String)
    case columnNameIsNotLiteral(_ argument: String)
    case accessorIsNotAllowed(_ property: String)

    var description: String {
        switch self {
        case .notAStruct:
            return "@Table can only be applied to a struct."

        case .missingTableName:
            return "@Table requires a table name string literal. ex) @Table(\"Users\")"

        case .noColumnDeclared:
            return "@Table requires at least one stored property as a column."

        case let .missingTypeAnnotation(property):
            return "@Table column '\(property)' needs an explicit type annotation."

        case let .unsupportedColumnType(property, type):
            return "@Table column '\(property)' has unsupported type '\(type)'. Int, Bool, String, Double and Float are supported."

        case let .accessorIsNotAllowed(property):
            return "@Table column '\(property)' cannot have an accessor. A table declares stored properties only, the entity is inferred from their types."

        case let .columnNameIsNotLiteral(argument):
            return "@Column(name:) requires a string literal, '\(argument)' is not one."
        }
    }
}
