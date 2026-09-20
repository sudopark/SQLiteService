//
//  MacroUsageExampleTests.swift
//
//
//  Created by sudo.park.
//

import XCTest
import SQLiteServiceMacros


// MARK: - define table with @Table macro

/**
 The macro generates Columns, Entity, tableName and scalar(_:for:) from this single declaration.
 The SQLite data type comes from the Swift type and the attributes only from @Column,
 so an optional property is not NOT NULL by itself.
 */
@Table("MacroUsers")
struct MacroUserTable {

    @Column(.primaryKey(autoIncrement: false)) var uid: String
    @Column(.notNull) var name: String
    var age: Int?
    @Column(.unique, .notNull) var email: String
    var phone: String?
    @Column(name: "intro") var introduction: String?
}

extension MacroUserTable.Entity {

    init(_ user: User) {
        self.init(uid: user.uid, name: user.name, age: user.age,
                  email: user.email, phone: user.phone, introduction: user.introduction)
    }
}


class MacroUsageExampleTests: XCTestCase {

    private var dbPath: String!
    private var service: SQLiteService!

    override func setUpWithError() throws {
        self.dbPath = try FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("macro_test_storage.db")
            .path
        self.service = SQLiteService()
    }

    override func tearDownWithError() throws {
        self.service.close()
        self.service = nil
        if let path = self.dbPath {
            try FileManager.default.removeItem(atPath: path)
        }
        self.dbPath = nil
    }

    func testMacroTableUsage() {

        let table = MacroUserTable.self
        let entities = (0..<10).map { MacroUserTable.Entity(User(dummy: $0)) }

        _ = self.service.open(path: self.dbPath)
        _ = self.service.run { try $0.createTableOrNot(table) }
        _ = self.service.run { try $0.insert(table, entities: entities) }

        let query = table.selectAll { $0.uid == "uid:1" }
        let result: Result<MacroUserTable.Entity?, Error> = self.service.run(execute: { try $0.loadOne(query) })
        let user = try? result.get()
        XCTAssertEqual(user?.uid, "uid:1")
        XCTAssertEqual(user?.name, "name:1")
    }
}
