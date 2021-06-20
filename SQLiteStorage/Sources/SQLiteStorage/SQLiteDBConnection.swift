//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/19.
//

import Foundation
import SQLite3


// MARK: - DataBase

public protocol DataBase {
    
    func userVersion() throws -> Int32
    
    func updateUserVersion(_ newValue: Int32) throws
    
    func createTableOrNot<T: Table>(_ table: T) throws
    
    func dropTable<T: Table>(_ table: T) throws

    func migrate<T: Table>(_ table: T, version: Int32) throws
    
    func load<T: Table>(_ table: T, query: SelectQuery<T>) throws -> [T.Model]
    
    func insert<T: Table>(_ table: T, models: [T.Model], shouldReplace: Bool) throws
    
    func update<T: Table>(_ table: T, query: UpdateQuery<T>) throws
    
    func delete<T: Table>(_ table: T, query: DeleteQuery<T>) throws
    
    func executeTransaction(_ statements: String) throws
}

extension DataBase {
    
    public func loadOne<T: Table>(_ table: T, query: SelectQuery<T>) throws -> T.Model? {
        let query = query.limit(1)
        return try self.load(table, query: query).first
    }
    
    public func insertOne<T: Table>(_ table: T, model: T.Model, shouldReplace: Bool) throws {
        try self.insert(table, models: [model], shouldReplace: shouldReplace)
    }
}

// MARK: - Connection

public protocol Connection {
    
    func open(path: String) throws
    
    func close() throws
}


// MARK: - SQLiteConnection

public class SQLiteDBConnection: Connection, DataBase {
    
    private var dbPointer: OpaquePointer?
    
    public init() { }
    
    deinit {
        try? self.close()
    }
    
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
    
    public func executeTransaction(_ statements: String) throws {

        guard statements.isEmpty == false else { return }
        
        let statementString = """
        BEGIN TRANSACTION;
        \(statements)
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


extension SQLiteDBConnection {
    
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


extension SQLiteDBConnection {
    
    public func userVersion() throws -> Int32 {
        let stmtText = "PRAGMA user_version;"
        var statement: OpaquePointer?
        defer {
            sqlite3_finalize(statement)
        }
        statement = try prepare(statement: stmtText)
        var version: Int32 = 0
        if sqlite3_step(statement) == SQLITE_ROW {
            version = sqlite3_column_int(statement, 0)
        }
        return version
    }
    
    public func updateUserVersion(_ newValue: Int32) throws {
        let stmtText = "PRAGMA user_version = \(newValue);"
        let updateResult = sqlite3_exec(dbPointer, stmtText, nil, nil, nil)
        guard updateResult == SQLITE_OK else {
            throw SQLiteErrors.execute(errorMessage())
        }
    }
}


extension SQLiteDBConnection {
    
    
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


extension SQLiteDBConnection {
    
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
        
        try executeTransaction(stmt)
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
