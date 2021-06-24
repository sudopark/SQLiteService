//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/20.
//

import XCTest

@testable import SQLiteStorage


class SQLiteStorageTests_migration: BaseSQLiteStorageTests { }


extension SQLiteStorageTests_migration {
    
    func migrationSteps(_ version: Int32, _ database: DataBase) throws {
        switch version {
        case 0, 1:
            try database.migrate(table, version: version)

        default: break
        }
    }
    
    private func saveOldUserData(oldTableName: String? = nil,
                                 oldColumns: [UserTable.Column] = UserTable.Column.allCases) -> [User] {
        let users: [User] = self.dummyUsers
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
        let oldUsers = self.dummyUsers
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
    
    func testStorage_whenMigrate_waitSyncAccess() {
        // given
        let expect = expectation(description: "rename table name")
        let _ = self.saveOldUserData(oldColumns: [.userID, .name, .age])
        
        self.storage.migrate(upto: 1, steps: { _, _ in
            Thread.sleep(forTimeInterval: 0.5)
        }) { _ in
            expect.fulfill()
        }
        
        // when
        let query = self.table.selectAll()
        let result = self.storage.run(execute: { try $0.load(self.table, query: query)})
        self.wait(for: [expect], timeout: self.timeout)
        
        // then
        XCTAssertNotNil(result)
    }
    
    func testStorage_whenMigrate_waitASyncAccess() {
        // given
        let expect = expectation(description: "rename table name")
        expect.expectedFulfillmentCount = 2
        var migrationEnd: TimeInterval?
        var userLoaded: TimeInterval?
        
        let _ = self.saveOldUserData(oldColumns: [.userID, .name, .age])
        
        self.storage.migrate(upto: 1, steps: { _, _ in
            Thread.sleep(forTimeInterval: 0.5)
        }) { _ in
            migrationEnd = Date().timeIntervalSince1970
            expect.fulfill()
        }
        
        // when
        let query = self.table.selectAll()
        self.storage.run(execute: { try $0.load(self.table, query: query) }) { _ in
            userLoaded = Date().timeIntervalSince1970
            expect.fulfill()
        }
        self.wait(for: [expect], timeout: self.timeout)
        
        // then
        XCTAssert(migrationEnd ?? 0 < userLoaded ?? -1)
    }
}
