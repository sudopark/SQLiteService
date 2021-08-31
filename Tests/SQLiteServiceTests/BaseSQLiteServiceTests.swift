//
//  BaseSQLiteServiceTests.swift
//  
//
//  Created by sudo.park on 2021/06/20.
//

import XCTest

@testable import SQLiteService


class BaseSQLiteServiceTests: XCTestCase {
    
    var dbPath: String!
    var table: UserTable.Type!
    var service: SQLiteService!
    
    var timeout: TimeInterval { 1 }
    
    override func setUpWithError() throws {
        let path = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                        .appendingPathComponent("storageTest.db")
                        .path
        self.dbPath = path
        self.table = UserTable.self
        self.service = .init()
    }
    
    override func tearDownWithError() throws {
        self.service.close{ _ in }
        self.table = nil
        self.service = nil
        try FileManager.default.removeItem(atPath: self.dbPath)
        self.dbPath = nil
    }
    
    func waitOpenDatabase() {
        let expect = expectation(description: "wait open and save users")
        self.service.open(path: self.dbPath) { _ in
            expect.fulfill()
        }
        self.wait(for: [expect], timeout: self.timeout)
    }
    
    var dummyUsers: [User] {
        return (0..<10).map{ User(userID: $0, name: "name:\($0)", age: $0, nickName: nil)}
    }
}


extension BaseSQLiteServiceTests {
    
    struct User: Equatable, RowValueType {
        let userID: Int
        let name: String
        var age: Int?
        var nickName: String?
        
        init(userID: Int, name: String, age: Int?, nickName: String?) {
            self.userID = userID
            self.name = name
            self.age = age
            self.nickName = nickName
        }
        
        init(_ cursor: CursorIterator) throws {
            self.userID = try cursor.next().unwrap()
            self.name = try cursor.next().unwrap()
            self.age = cursor.next()
            self.nickName = cursor.next()
        }
        
        static func == (_ lhs: Self, _ rhs: Self) -> Bool {
            return lhs.userID == rhs.userID
                && lhs.name == rhs.name
                && lhs.age == rhs.age
                && lhs.nickName == rhs.nickName
        }
    }

    struct UserTable: Table {
        
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
        
        typealias EntityType = User
        typealias ColumnType = Column
        
        static var tableName: String { "users" }
        
        static func scalar(_ entity: SQLiteServiceTests_migration.User, for column: Column) -> ScalarType? {
            switch column {
            case .userID: return entity.userID
            case .name: return entity.name
            case .age: return entity.age
            case .nickname: return entity.nickName
            }
        }
        
        static var testRenameColumn: Bool = false
        
        static func migrateStatement(for version: Int32) -> String? {
            switch version {
            case 0 where Self.testRenameColumn == false:
                return Self.addColumnStatement(.nickname, oldTableName: "old_users")
                
            case 1:
                return self.renameStatement(from: "old_users")
                
            case 2 where Self.testRenameColumn == true:
                return Self.modfiyColumns(to: Column.allCases.map{ $0.rawValue },
                                          from: ["userID", "old_name", "age", "nickname"])
                
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
