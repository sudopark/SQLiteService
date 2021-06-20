//
//  BaseSQLiteStorageTests.swift
//  
//
//  Created by sudo.park on 2021/06/20.
//

import XCTest

@testable import SQLiteStorage


class BaseSQLiteStorageTests: XCTestCase {
    
    var dbPath: String!
    var table: UserTable.Type!
    var storage: SQLiteStorage!
    
    var timeout: TimeInterval { 1 }
    
    override func setUpWithError() throws {
        let path = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                        .appendingPathComponent("storageTest.db")
                        .path
        self.dbPath = path
        self.table = UserTable.self
        self.storage = .init()
    }
    
    override func tearDownWithError() throws {
        self.storage.close{ _ in }
        self.table = nil
        self.storage = nil
        try FileManager.default.removeItem(atPath: self.dbPath)
        self.dbPath = nil
    }
    
    func waitOpenDatabase() {
        let expect = expectation(description: "wait open and save users")
        self.storage.open(path: self.dbPath) { _ in
            expect.fulfill()
        }
        self.wait(for: [expect], timeout: self.timeout)
    }
}


extension BaseSQLiteStorageTests {
    
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
        
        static func serialize(model: SQLiteStorageTests_migration.User, for column: Column) -> ScalarType? {
            switch column {
            case .userID: return model.userID
            case .name: return model.name
            case .age: return model.age
            case .nickname: return model.nickName
            }
        }
        
        static func deserialize(_ cursor: OpaquePointer) throws -> SQLiteStorageTests_migration.User {
            
            let id: Int = try cursor[0].unwrap()
            let name: String = try cursor[1].unwrap()
            let age: Int? = cursor[2]
            let nickName: String? = cursor[3]
            
            return User(userID: id, name: name, age: age, nickName: nickName)
        }
        
        static var testRenameColumn: Bool = false
        
        static func migrateStatement(for version: Int32) -> String? {
            switch version {
            case 0 where Self.testRenameColumn == false:
                return Self.addColumnStatement(.nickname)
                
            case 0 where Self.testRenameColumn == true:
                return Self.modfiyColumns(to: Column.allCases.map{ $0.rawValue },
                                          from: ["userID", "old_name", "age", "nickname"])
                
            case 1:
                return self.renameStatement("old_users")
                
            default: return nil
            }
        }
    }
}

extension Result {
    
    func unwrap() -> Success? {
        guard case let .success(value) = self else { return nil }
        return value
    }
}
