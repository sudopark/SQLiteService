//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/20.
//

import XCTest

@testable import SQLiteService


class SQLiteServiceTests_migration: BaseSQLiteServiceTests { }


extension SQLiteServiceTests_migration {
    
    func migrationSteps(_ version: Int32, _ database: DataBase) throws {
        switch version {
        case 0, 1:
            try? database.migrate(table, version: version)

        default: break
        }
    }
    
    func testService_migration_addColumn() {
        // given
        let expect = expectation(description: "add column migration")
        self.waitOpenDatabase()
        
        let entities = self.dummyUsers.map{ UserTableV0.EntityType(user: $0) }
        _ = self.service.run { try $0.insert(UserTableV0.self, entities: entities) }
        
        // when
        self.service.migrate(upto: 1, steps: self.migrationSteps) { _ in
            expect.fulfill()
        }
        self.wait(for: [expect], timeout: self.timeout)
        
        // then
        let updateQuery = UserTableV1
            .update { [$0.nickName == "nick_name"] }
            .where { $0.userID == 0 }
        _ = self.service.run { try $0.update(UserTableV1.self, query: updateQuery) }
        
        let query = UserTableV1.selectAll { $0.userID == 0 }
        let migratedUser0 = try? self.service.run(execute: { try $0.loadOne(UserTableV1.self, query: query)}).get()
        XCTAssertNotNil(migratedUser0)
        XCTAssertEqual(migratedUser0?.nickName, "nick_name")
    }
    
    func testService_migration_renameTable() {
        // given
        let expect = expectation(description: "rename table name")
        self.waitOpenDatabase()
        
        self.service.run { try $0.updateUserVersion(1) }
        let entities = self.dummyUsers.map{ UserTableV1.EntityType(user: $0) }
        _ = self.service.run { try $0.insert(UserTableV1.self, entities: entities) }
        
        // when
        self.service.migrate(upto: 2, steps: self.migrationSteps(_:_:)) { _ in
            expect.fulfill()
        }
        self.wait(for: [expect], timeout: self.timeout)
        
        // then
        let query = UserTableV2.selectAll()
        let migratedUsers = self.service.run(execute: { try $0.load(UserTableV2.self, query: query)}).unwrap()
        XCTAssertEqual(migratedUsers?.count, 10)
    }
    
    func testService_migration_renmaeColumnName() {
        // given
        let expect = expectation(description: "rename table name")
        self.waitOpenDatabase()
        
        self.service.run { try $0.updateUserVersion(2) }
        let entities = self.dummyUsers.map{ UserTableV2.EntityType(user: $0) }
        _ = self.service.run { try $0.insert(UserTableV2.self, entities: entities) }
    
        // when
        self.table.testRenameColumn = true
        self.service.migrate(upto: 3, steps: self.migrationSteps(_:_:)) { _ in
            expect.fulfill()
        }
        self.wait(for: [expect], timeout: self.timeout)
        
        // then
        let query = self.table.selectAll()
        let migratedUsers = self.service.run(execute: { try $0.load(self.table, query: query)}).unwrap()
        XCTAssertEqual(migratedUsers?.count, 10)
    }
    
    func testService_whenAfterFinalizeMigrationAction_callFinalizedClosure() {
        // given
        let expect = expectation(description: "call finalized closure if exists when after migration end")
        self.waitOpenDatabase()
        var isFinalized = false
        
        // when
        self.service.migrate(upto: 3, steps: { _, _ in }, finalized: { _, _ in
            isFinalized = true
            expect.fulfill()
        }) { _ in }
        self.wait(for: [expect], timeout: self.timeout)
        
        // then
        XCTAssertEqual(isFinalized, true)
    }
}


extension SQLiteServiceTests_migration {
    
    func testService_whenMigrate_waitSyncAccess() {
        // given
        let expect = expectation(description: "wait sync access until migration end")
        
        self.waitOpenDatabase()
        let entities = self.dummyUsers.map{ UserTableV0.EntityType(user: $0) }
        _ = self.service.run { try $0.insert(UserTableV0.self, entities: entities) }
        
        self.service.migrate(upto: 1, steps: { _, _ in
            Thread.sleep(forTimeInterval: 0.5)
        }) { _ in
            expect.fulfill()
        }
        
        // when
        let query = self.table.selectAll()
        let result = self.service.run(execute: { try $0.load(self.table, query: query)})
        self.wait(for: [expect], timeout: self.timeout)
        
        // then
        XCTAssertNotNil(result)
    }
    
    func testService_whenMigrate_waitASyncAccess() {
        // given
        let expect = expectation(description: "wait async access until migration end")
        expect.expectedFulfillmentCount = 2
        var migrationEnd: TimeInterval?
        var userLoaded: TimeInterval?
        
        self.waitOpenDatabase()
        let entities = self.dummyUsers.map{ UserTableV0.EntityType(user: $0) }
        _ = self.service.run { try $0.insert(UserTableV0.self, entities: entities) }
        
        self.service.migrate(upto: 1, steps: { _, _ in
            Thread.sleep(forTimeInterval: 0.5)
        }) { _ in
            migrationEnd = Date().timeIntervalSince1970
            expect.fulfill()
        }
        
        // when
        let query = self.table.selectAll()
        self.service.run(execute: { try $0.load(self.table, query: query) }) { _ in
            userLoaded = Date().timeIntervalSince1970
            expect.fulfill()
        }
        self.wait(for: [expect], timeout: self.timeout)
        
        // then
        XCTAssert(migrationEnd ?? 0 < userLoaded ?? -1)
    }
}


private extension SQLiteServiceTests_migration {

    struct UserTableV0: Table {
        
        enum Columns: String, TableColumn {
            case userID
            case name = "old_name"
            case age
            
            var dataType: ColumnDataType {
                switch self {
                case .userID: return .integer([.primaryKey(autoIncrement: false)])
                case .name: return .text([.notNull])
                case .age: return .integer([])
                }
            }
        }
        
        class UserEntityV0: RowValueType {
            let userID: Int
            let name: String
            let age: Int?
            
            init(user: User) {
                self.userID = user.userID
                self.name = user.name
                self.age = user.age
            }
            
            required init(_ cursor: CursorIterator) throws {
                self.userID = try cursor.next().unwrap()
                self.name = try cursor.next().unwrap()
                self.age = cursor.next()
            }
        }
        
        static var tableName: String { "old_users" }
        typealias ColumnType = Columns
        typealias EntityType = UserEntityV0
        
        static func scalar(_ entity: UserEntityV0, for column: Columns) -> ScalarType? {
            switch column {
            case .userID: return entity.userID
            case .name: return entity.name
            case .age: return entity.age
            }
        }
    }
    
    // v0 -> v1: add column
    struct UserTableV1: Table {
        
        enum Columns: String, TableColumn {
            case userID
            case name = "old_name"
            case age
            case nickName
            
            var dataType: ColumnDataType {
                switch self {
                case .userID: return .integer([.primaryKey(autoIncrement: false)])
                case .name: return .text([.notNull])
                case .age: return .integer([])
                case .nickName: return .text([])
                }
            }
        }
        
        class UserEntityV1: UserTableV0.UserEntityV0 {
            var nickName: String?
            
            override init(user: BaseSQLiteServiceTests.User) {
                super.init(user: user)
                self.nickName = user.nickName
            }
            
            required init(_ cursor: CursorIterator) throws {
                try super.init(cursor)
                self.nickName = cursor.next()
            }
        }

        static var tableName: String { "old_users" }
        typealias ColumnType = Columns
        typealias EntityType = UserEntityV1
        
        static func scalar(_ entity: UserEntityV1, for column: Columns) -> ScalarType? {
            switch column {
            case .userID: return entity.userID
            case .name: return entity.name
            case .age: return entity.age
            case .nickName: return entity.nickName
            }
        }
    }
    
    // v1 -> v2: renmae table
    struct UserTableV2: Table {
        
        typealias ColumnType = UserTableV1.Columns
        typealias EntityType = UserTableV1.EntityType
        
        static var tableName: String { "users" }
        
        static func scalar(_ entity: SQLiteServiceTests_migration.UserTableV1.EntityType, for column: SQLiteServiceTests_migration.UserTableV1.Columns) -> ScalarType? {
            return UserTableV1.scalar(entity, for: column)
        }
    }
}
