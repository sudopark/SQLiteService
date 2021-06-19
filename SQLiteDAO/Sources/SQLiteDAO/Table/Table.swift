//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import Foundation
import SQLite3


public protocol Table {
    
    associatedtype Model
    associatedtype ColumnType: TableColumn
    
    static var tableName: String { get }

    func serialize(model: Model) throws -> [StorageDataType?]
    
    func deserialize(cursor: OpaquePointer?) throws -> Model
    
    func migrateStatement(for version: Int32) -> String?
    
    var createStatement: String { get }
}


extension Table {
    
    var createStatement: String {
        let prefix = "CREATE TABLE IF NOT EXISTS \(Self.tableName) ("
        let columns = ColumnType.allCases.map{ $0 }
        let columnStrings = columns.map{ $0.toString() }.joined(separator: ", ")
        let suffix = ");"
        return "\(prefix)\(columnStrings)\(suffix)"
    }
    
    func insertStatement(model: Model, shouldReplace: Bool) throws -> String {
        let orAnd = shouldReplace ? "REPLACE" : "IGNORE"
        let prefix = "INSERT OR \(orAnd) INTO \(Self.tableName)"
        let keyStrings = ColumnType.allCases.map{ $0.rawValue }.joined(separator: ", ")
        let valueStrings = try self.serialize(model: model)
            .map{ $0.asStatementText() }
            .joined(separator: ", ")
        return "\(prefix) (\(keyStrings)) VALUES (\(valueStrings));"
    }
    
    var dropStatement: String {
        return "DROP TABLE IF EXISTS \(Self.tableName)"
    }
    
    public func migrateStatement(for version: Int32) -> String? {
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
    func unwrap() throws -> Wrapped {
        switch self {
        case .some(let unwraped): return unwraped
        case .none: throw SQLiteErrors.step("unwrap")
        }
    }
}
