//
//  Macros.swift
//
//
//  Created by sudo.park.
//

@_exported import SQLiteService


/// Generates `Table` conformance from a single column declaration list.
///
/// - `Columns`: a `TableColumn` enum, one case per stored property in declaration order
/// - `Entity`: a `RowValueType` struct with the same properties, memberwise init and cursor init
/// - `tableName`, `scalar(_:for:)`, `ColumnType` / `EntityType` typealiases
@attached(
    member,
    names: named(Columns), named(Entity), named(ColumnType), named(EntityType),
    named(tableName), named(scalar)
)
@attached(extension, conformances: Table)
public macro Table(_ name: String) = #externalMacro(
    module: "SQLiteServiceMacrosPlugin", type: "TableMacro"
)


/// Declares the column attributes and the column name of a `@Table` property.
///
/// The SQLite data type comes from the Swift type, the attributes only from this macro —
/// an optional property is not `NOT NULL` by itself.
@attached(peer)
public macro Column(
    _ attributes: ColumnDataAttribute...,
    name: String? = nil
) = #externalMacro(module: "SQLiteServiceMacrosPlugin", type: "ColumnMacro")
