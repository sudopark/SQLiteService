//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/19.
//

import Foundation
import SQLite3


// MARK: - Connection

public protocol Connection {
    
    func open(path: String) throws
    
    func close() throws
    
    func createTableOrNot<T: Table>(_ table: T) throws
    
    func dropTable<T: Table>(_ table: T) throws

    func migrate<T: Table>(_ table: T, version: Int32) throws
    
    func load<T: Table>(_ table: T, query: SelectQuery<T>) throws -> [T.Model]
    
    func insert<T: Table>(_ table: T, models: [T.Model], shouldReplace: Bool) throws
    
    func update<T: Table>(_ table: T, query: UpdateQuery<T>) throws
    
    func delete<T: Table>(_ table: T, query: DeleteQuery<T>) throws
}

// MARK: - SQLiteConnection

public class SQLiteConnection: Connection {
    
    private var dbPointer: OpaquePointer?
    
    public init() { } 
    
    private func errorMessage(_ pointer: OpaquePointer? = nil) -> String {
        let pointer = pointer ?? self.dbPointer
        if let errorPointer = sqlite3_errmsg(pointer) {
            return String(cString: errorPointer)
        }
        return "Unknown"
    }
    
    private func prepare(statement: String) throws -> OpaquePointer? {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(self.dbPointer, statement, -1, &stmt, nil) == SQLITE_OK else {
            throw SQLiteErrors.prepare(errorMessage())
        }
        return stmt
    }
    
    private func executeTransaction<T: Table>(_ table: T,
                                               innerStatement: String) throws {
        if innerStatement.isEmpty {
            return
        }
        
        try createTableOrNot(table)
        
        let statementString = """
        BEGIN TRANSACTION;
        \(innerStatement)
        COMMIT;
        """
        
        let result = sqlite3_exec(dbPointer, statementString, nil, nil, nil)
        let _ = sqlite3_exec(dbPointer, "END TRANSACTION", nil, nil, nil)
        
        guard result == SQLITE_OK else {
            throw SQLiteErrors.transation(errorMessage())
        }
    }
    
    private func endTransation() {
        _ = sqlite3_exec(dbPointer, "END TRANSACTION", nil, nil, nil)
    }
}


extension SQLiteConnection {
    
    public func open(path: String) throws {
        
        var newConnection: OpaquePointer?
        
        guard sqlite3_open(path, &newConnection) == SQLITE_OK else {
            throw SQLiteErrors.open(self.errorMessage(newConnection))
        }
        
        self.dbPointer = newConnection
    }
    
    public func close() throws {
        guard let connection = self.dbPointer else {
            throw SQLiteErrors.close
        }
        sqlite3_close(connection)
    }
}


extension SQLiteConnection {
    
    
    public func createTableOrNot<T: Table>(_ table: T) throws {
        
        let createStatement = try prepare(statement: table.createStatement)
        
        defer {
            sqlite3_finalize(createStatement)
        }
        
        guard sqlite3_step(createStatement) == SQLITE_DONE else {
            throw SQLiteErrors.step(errorMessage())
        }
    }
    
    public func dropTable<T>(_ table: T) throws where T : Table {

        let dropStatement = try prepare(statement: table.dropStatement)
        
        guard sqlite3_step(dropStatement) == SQLITE_DONE else {
            throw SQLiteErrors.step(errorMessage())
        }
    }
    
    public func migrate<T>(_ table: T, version: Int32) throws where T : Table {
        
        guard let migrateStatement = table.migrateStatement(for: version) else { return }
        
        defer {
            self.endTransation()
        }
        
        let result = sqlite3_exec(dbPointer, migrateStatement, nil, nil, nil)
        guard result == SQLITE_OK else {
            throw SQLiteErrors.migration(self.errorMessage())
        }
    }
}


extension SQLiteConnection {
    
    public func load<T>(_ table: T, query: SelectQuery<T>) throws -> [T.Model] where T : Table {
        
        let stmt = try prepare(statement: query.asStatement())
        
        var models: [T.Model] = []
        var result = sqlite3_step(stmt)
        while result == SQLITE_ROW {
            if let model = try? table.deserialize(cursor: stmt) {
                models.append(model)
            }
            result = sqlite3_step(stmt)
        }
        
        sqlite3_finalize(stmt)
        return models
    }
    
    public func insert<T>(_ table: T, models: [T.Model], shouldReplace: Bool) throws where T : Table {
        
        guard models.isEmpty == false else { return }
        
        try self.createTableOrNot(table)
        
        let stmt = try models
            .map{ try table.insertStatement(model: $0, shouldReplace: shouldReplace) }
            .joined(separator: "\n")
        
        try executeTransaction(table, innerStatement: stmt)
    }
    
    public func update<T>(_ table: T, query: UpdateQuery<T>) throws where T : Table {
        
        try self.createTableOrNot(table)
        
        let stmt = try prepare(statement: query.asStatement())
        
        defer {
            sqlite3_finalize(stmt)
        }
        
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SQLiteErrors.step(errorMessage())
        }
    }
    
    public func delete<T>(_ table: T, query: DeleteQuery<T>) throws where T : Table {
        
        try self.createTableOrNot(table)
        
        let stmt = try prepare(statement: query.asStatement())
        
        defer {
            sqlite3_finalize(stmt)
        }
        
        if sqlite3_step(stmt) != SQLITE_DONE {
            throw SQLiteErrors.step(errorMessage())
        }
    }
}
