//
//  SQLiteServiceTests.swift
//  
//
//  Created by sudo.park on 2021/06/21.
//

import XCTest

@testable import SQLiteService


class SQLiteServiceTests: BaseSQLiteServiceTests { }

extension SQLiteServiceTests {
    
    private func saveDummyUsers() {
        let users = self.dummyUsers
        self.service.run(execute: { try $0.insert(UserTable.self, models: users, shouldReplace: true)})
    }
    
    func testService_loadScalar() {
        // given
        self.waitOpenDatabase()
        self.saveDummyUsers()
        
        // when
        let users = UserTable.self
        let query = users.selectSome{ [$0.name] }.where{ $0.userID == 3 }
        let loadResult: Result<String?, Error> = self.service.run(execute: { try $0.loadValue(query) })
        
        // then
        let name = loadResult.unwrap()
        XCTAssertEqual(name, "name:3")
    }
    
    struct UserAge: RowValueType {
        let userID: Int
        let age: Int?
        
        init(_ cursor: CursorIterator) throws {
            self.userID = try cursor.next().unwrap()
            self.age = cursor.next()
        }
    }
    
    func testService_loadRowValue() {
        // given
        self.waitOpenDatabase()
        self.saveDummyUsers()
        
        // when
        let users = UserTable.self
        let query = users.selectSome{ [$0.userID, $0.age] }
        let loadResult: Result<[UserAge], Error> = self.service.run(execute: { try $0.load(query) })
        
        // then
        let ages = loadResult.unwrap()?.map{ $0.age }
        XCTAssertEqual(ages, Array(0..<10))
    }
    
    struct UserWithK2: RowValueType {
        let user: User
        let k2: String
        
        init(_ cursor: CursorIterator) throws {
            self.user = try User(cursor)
            self.k2 = try cursor.next().unwrap()
        }
    }
    
    func testService_loadUserJoinWithOtherTable() {
        // given
        self.waitOpenDatabase()
        self.saveDummyUsers()
        let dummies: [Dummies.Model] = (0..<10).map{ .init(k1: $0, k2: "some:\($0)") }
        self.service.run(execute: { try $0.insert(Dummies.Table1.self, models: dummies, shouldReplace: true) })
        
        // when
        let users = UserTable.self
        let userSelect = users.selectAll()
        let dummySelect = Dummies.Table1.selectSome{ _ in [.k2] }
        let joinQuery = userSelect.innerJoin(with: dummySelect, on: { ($0.userID, $1.k1) })
        let loadResult: Result<[UserWithK2], Error> = self.service.run(execute: { try $0.load(joinQuery) })
        
        // then
        let userK2s = loadResult.unwrap()
        let k2Values = userK2s?.map{ $0.k2 }
        XCTAssertEqual(k2Values, dummies.map{ $0.k2 })
    }
}
