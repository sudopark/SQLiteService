//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import Foundation
import SQLite3


// MARK: - Table

public protocol Table: Sendable {
    
    associatedtype EntityType: RowValueType
    associatedtype ColumnType: TableColumn
    
    static var tableName: String { get }
    
    static func scalar(_ entity: EntityType, for column: ColumnType) -> ScalarType?
    
    static var createStatement: String { get }
    
    static func migrateStatement(for version: Int32) -> String?
}

extension Table {
    
    public static func serialize(entity: EntityType) throws -> [ScalarType?] {
        let allColumns = ColumnType.allCases
        return allColumns.map{ self.scalar(entity, for: $0) }
    }
}


// MARK: - Table -> make statements

extension Table {
    
    public static var createStatement: String {
        let primaryColumns = self.ColumnType.allCases.filter{ $0.isPrimaryKey }
        return primaryColumns.isEmpty
            ? self.createStatementWithoutPrimaryKey()
            : self.createStatementWithPrimaryKeys(primaryColumns)
    }
    
    private static func createStatementWithoutPrimaryKey() -> String {
        let prefix = "CREATE TABLE IF NOT EXISTS \(Self.tableName) ("
        let columns = ColumnType.allCases.map{ $0 }
        let columnStrings = columns.map{ $0.toString() }.joined(separator: ", ")
        let suffix = ");"
        return "\(prefix)\(columnStrings)\(suffix)"
    }
    
    private static func createStatementWithPrimaryKeys(_ primaryKeyColumns: [ColumnType]) -> String {
        let prefix = "CREATE TABLE IF NOT EXISTS \(Self.tableName) ("
        let columns = ColumnType.allCases.map{ $0 }
        let columnStrings = columns.map{ $0.toString(withoutPrimaryKey: true) }.joined(separator: ", ")
        let primaryKey = primaryKeyColumns.asPrimaryKeyStrings()
        let suffix = ");"
        return "\(prefix)\(columnStrings),\(primaryKey)\(suffix)"
    }
    
    public static func insertStatement(entity: EntityType, shouldReplace: Bool) throws -> String {
        let orAnd = shouldReplace ? "REPLACE" : "IGNORE"
        let prefix = "INSERT OR \(orAnd) INTO \(Self.tableName)"
        let keyStrings = ColumnType.allCases.map{ $0.rawValue }.joined(separator: ", ")
        let valueStrings = try self.serialize(entity: entity)
            .map{ $0.asStatementText() }
            .joined(separator: ", ")
        return "\(prefix) (\(keyStrings)) VALUES (\(valueStrings));"
    }
    
    public static var dropStatement: String {
        return "DROP TABLE IF EXISTS \(Self.tableName)"
    }
    
    public static func renameStatement(from oldName: String) -> String {
        return "ALTER TABLE \(oldName) RENAME TO \(Self.tableName);"
    }
    
    public static func addColumnStatement(_ column: ColumnType, oldTableName: String? = nil) -> String {
        let tableName = oldTableName ?? self.tableName
        return "ALTER TABLE \(tableName) ADD COLUMN \(column.toString());"
    }
    
    public static func modfiyColumns(tempTable: String? = nil,
                                     oldTableName: String? = nil,
                                     to newColumns: [String],
                                     from oldColumns: [String]) -> String {
        
        let tableName = oldTableName ?? self.tableName
        
        let fromColumns = oldColumns.joined(separator: ", ")
        let toColumns = newColumns.joined(separator: ", ")
        
        let tempTable = tempTable ?? "temp_\(tableName)"
        let copyStmt = "INSERT INTO \(tempTable) (\(toColumns)) select \(fromColumns) from \(tableName);"
        let dropStmt = self.dropStatement
        let renameStmt = self.renameStatement(from: tempTable)
        
        return [copyStmt, dropStmt, renameStmt].joined(separator: "\n")
    }
    
    public static func migrateStatement(for version: Int32) -> String? {
        return nil
    }
}

extension OpaquePointer {
    
    subscript<T>(index: Int) -> T? {
        let index32 = index.asInt32
        let type = sqlite3_column_type(self, index32)
        switch type {
        case SQLITE_FLOAT:
            return Double(sqlite3_column_double(self, index32)) as? T
            
        case SQLITE_INTEGER where T.self == Bool.self:
            let int = Int(sqlite3_column_int64(self, index32))
            return (int == 0 ? false : true) as? T
            
        case SQLITE_INTEGER:
            return Int(sqlite3_column_int64(self, index32)) as? T
            
        case SQLITE_TEXT:
            guard let pointer = sqlite3_column_text(self, index32) else { return nil }
            return String(cString: pointer) as? T
            
        default: return nil
        }
    }
}

extension Optional {
    public func unwrap() throws -> Wrapped {
        switch self {
        case .some(let unwraped): return unwraped
        case .none: throw SQLiteErrors.step("unwrap")
        }
    }
}

private extension ColumnDataAttribute {
    
    var isPrimaryKey: Bool {
        guard case .primaryKey = self else { return false }
        return true
    }
}

private extension TableColumn {
    
    var isPrimaryKey: Bool {
        switch self.dataType {
        case let .integer(attrs),
             let .real(attrs),
             let .char(_, attrs),
             let .text(attrs):
            return attrs.contains(where: { $0.isPrimaryKey} )
        }
    }
}
