//
//  SQLiteServiceTests+Concurrency.swift
//  
//
//  Created by sudo.park on 2022/03/26.
//

import XCTest

@testable import SQLiteService


@available(iOS 13.0.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
class SQLiteServiceTests_Concurrency: BaseSQLiteServiceTests { }

@available(iOS 13.0.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
extension SQLiteServiceTests_Concurrency {
    
    func testService_openDatabase() async {
        // given
        // when
        let opened: Void? = try? await self.service.async.open(path: self.dbPath)
        
        // then
        XCTAssertNotNil(opened)
    }
    
    func testService_runTasks() async {
        // given
        let _: Void? = try? await self.service.async.open(path: self.dbPath)
        
        // when
        let _: Void? = try? await self.service.async.run { db in
            try db.insert(UserTable.self, entities: self.dummyUsers)
        }
        let users = try? await self.service.async.run { db -> [User] in
            let query = UserTable.selectAll()
            return try db.load(query)
        }
        
        // then
        XCTAssertEqual(users?.count, self.dummyUsers.count)
    }
}
