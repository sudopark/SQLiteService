//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/20.
//

import XCTest

@testable import SQLiteStorage


class SQLiteStorageTests_migration: XCTestCase {
    
    var dbPath: String!
    var table: UserTable!
    var storage: SQLiteStorage!
    
    var timeout: TimeInterval { 1 }
    
    override func setUpWithError() throws {
        let path = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                        .appendingPathComponent("storageTest.db")
                        .path
        self.dbPath = path
        self.table = UserTable()
        self.storage = .init()
    }
    
    override func tearDownWithError() throws {
        self.storage.close{ _ in }
        self.table = nil
        self.storage = nil
        try FileManager.default.removeItem(atPath: self.dbPath)
        self.dbPath = nil
    }
}


extension SQLiteStorageTests_migration {
    
    private func waitOpenDatabase() {
        let expect = expectation(description: "wait open and save users")
        self.storage.open(path: self.dbPath) { _ in
            expect.fulfill()
        }
        self.wait(for: [expect], timeout: self.timeout)
    }
    
    func migrationSteps(_ version: Int32, _ database: DataBase) throws {
        switch version {
        case 0, 1:
            try database.migrate(table, version: version)

        default: break
        }
    }
    
    private func saveOldUserData(oldTableName: String? = nil,
                                 oldColumns: [UserTable.Column] = UserTable.Column.allCases) -> [User] {
        let users: [User] = (0..<10).map{ User(userID: $0, name: "name:\($0)", age: $0, nickName: nil)}
        self.waitOpenDatabase()
        
        let tableName = oldTableName ?? UserTable.tableName
        let keys = oldColumns.map{ $0.rawValue }
        let keyAndTypesPairs = oldColumns.map{ "\($0.rawValue) \($0.dataType.toString())"}
        let createStmt: String = """
            CREATE TABLE IF NOT EXISTS \(tableName) (
                \(keyAndTypesPairs.joined(separator: ","))
            );
        """
        
        let insertStmts = users.map { user -> String in
            let valueTexts = oldColumns.map{ self.table.serialize(model: user, for: $0) }.map{ $0.asStatementText() }
            return """
                INSERT OR IGNORE INTO \(tableName)
                (\(keys.joined(separator: ", ")))
                VALUES
                (\(valueTexts.joined(separator: ", ")));
            """
        }
        
        let stmts = ([createStmt] + insertStmts).joined(separator: "\n")
        self.storage.run(execute: { try $0.executeTransaction(stmts) })
        
        return users
    }
    
    func testStorage_migration_addColumn() {
        // given
        let expect = expectation(description: "add column migration")
        let oldUsers = self.saveOldUserData(oldColumns: [.userID, .name, .age])
        
        // when
        self.storage.migrate(upto: 1, steps: self.migrationSteps) { _ in
            expect.fulfill()
        }
        self.wait(for: [expect], timeout: self.timeout)
        
        // then
        let query = self.table.selectAll()
        let migratedUsers = self.storage.run(execute: { try $0.load(self.table, query: query)}).unwrap()
        XCTAssertEqual(migratedUsers, oldUsers)
    }
    
    func testStorage_migration_renameTable() {
        // given
        let expect = expectation(description: "rename table name")
        let oldUsers = self.saveOldUserData(oldColumns: [.userID, .name, .age])
        
        
        // when
        self.storage.migrate(upto: 2, steps: self.migrationSteps(_:_:)) { _ in
            expect.fulfill()
        }
        self.wait(for: [expect], timeout: self.timeout)
        
        // then
        let query = self.table.selectAll()
        let migratedUsers = self.storage.run(execute: { try $0.load(self.table, query: query)}).unwrap()
        XCTAssertEqual(migratedUsers, oldUsers)
    }
    
    func testStorage_migration_renmaeColumnName() {
        // given
        let expect = expectation(description: "rename table name")
        let oldUsers: [User] = (0..<10).map{ User(userID: $0, name: "name:\($0)", age: $0, nickName: nil)}
        self.waitOpenDatabase()
    
        let createStmt: String = """
            CREATE TABLE IF NOT EXISTS users (
                userID INTEGER PRIMARY KEY AUTOINCREMENT,
                old_name TEXT NOT NULL,
                age INTEGER,
                nickname TEXT
            );
        """
        
        let insertStmts = oldUsers.map { user -> String in
            return """
                INSERT OR IGNORE INTO users
                (userID, old_name, age, nickname)
                VALUES
                (\(user.userID.toString()), '\(user.name)', \(user.age!), NULL);
            """
        }
        
        let stmts = ([createStmt] + insertStmts).joined(separator: "\n")
        self.storage.run(execute: { try $0.executeTransaction(stmts) })
        
        // when
        self.table.testRenameColumn = true
        self.storage.migrate(upto: 1, steps: self.migrationSteps(_:_:)) { _ in
            expect.fulfill()
        }
        self.wait(for: [expect], timeout: self.timeout)
        
        // then
        let query = self.table.selectAll()
        let migratedUsers = self.storage.run(execute: { try $0.load(self.table, query: query)}).unwrap()
        XCTAssertEqual(migratedUsers, oldUsers)
    }
}

extension SQLiteStorageTests_migration {
    
    struct User: Equatable {
        let userID: Int
        let name: String
        var age: Int?
        var nickName: String?
        
        static func == (_ lhs: Self, _ rhs: Self) -> Bool {
            return lhs.userID == rhs.userID
                && lhs.name == rhs.name
                && lhs.age == rhs.age
                && lhs.nickName == rhs.nickName
        }
    }

    class UserTable: Table {
        
        enum Column: String, TableColumn {
            case userID
            case name
            case age
            case nickname
            
            var dataType: ColumnDataType {
                switch self {
                case .userID: return .integer([.primaryKey(autoIncrement: false)])
                case .name: return .text([.notNull])
                case .age: return .integer([])
                case .nickname: return .text([])
                }
            }
        }
        
        typealias Model = User
        typealias ColumnType = Column
        
        static var tableName: String { "users" }
        
        func serialize(model: SQLiteStorageTests_migration.User, for column: Column) -> StorageDataType? {
            switch column {
            case .userID: return model.userID
            case .name: return model.name
            case .age: return model.age
            case .nickname: return model.nickName
            }
        }
        
        func deserialize(cursor: OpaquePointer?) throws -> SQLiteStorageTests_migration.User {
            guard let cursor = cursor else {
                throw SQLiteErrors.step("deserialize")
            }
            
            let id: Int = try cursor[0].unwrap()
            let name: String = try cursor[1].unwrap()
            let age: Int? = cursor[2]
            let nickName: String? = cursor[3]
            
            return User(userID: id, name: name, age: age, nickName: nickName)
        }
        
        var testRenameColumn: Bool = false
        
        func migrateStatement(for version: Int32) -> String? {
            switch version {
            case 0 where testRenameColumn == false:
                return self.addColumnStatement(.nickname)
                
            case 0 where testRenameColumn == true:
                return self.modfiyColumns(to: Column.allCases.map{ $0.rawValue },
                                          from: ["userID", "old_name", "age", "nickname"])
                
            case 1:
                return self.renameStatement("old_users")
                
            default: return nil
            }
        }
    }
}

private extension Result {
    
    func unwrap() -> Success? {
        guard case let .success(value) = self else { return nil }
        return value
    }
}
