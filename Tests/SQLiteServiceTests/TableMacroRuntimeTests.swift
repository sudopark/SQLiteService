//
//  TableMacroRuntimeTests.swift
//
//
//  Created by sudo.park.
//

import XCTest
import SQLiteServiceMacros

@testable import SQLiteService


@Table("macro_users")
fileprivate struct MacroTestTable {

    @Column(.primaryKey(autoIncrement: false)) var uid: String
    @Column(.notNull) var name: String
    var age: Int?
    @Column(.unique, .notNull) var email: String
    var phone: String?
    @Column(name: "intro") var introduction: String?
}

@Table("macro_users")
fileprivate struct MacroTestTableV1 {

    @Column(.primaryKey(autoIncrement: false)) var uid: String
    @Column(.notNull) var name: String
    var age: Int?
    @Column(.unique, .notNull) var email: String
    var phone: String?
    @Column(name: "intro") var introduction: String?
    var isBlocked: Bool?
}

extension MacroTestTableV1 {

    static func migrateStatement(for version: Int32) -> String? {
        switch version {
        case 0: return self.addColumnStatement(.isBlocked)
        default: return nil
        }
    }
}


class TableMacroRuntimeTests: BaseSQLiteServiceTests {

    fileprivate var dummyUser: MacroTestTable.Entity {
        return .init(
            uid: "uid:1", name: "name", age: 30,
            email: "email@some.com", phone: "010-0000-0000", introduction: "intro text"
        )
    }
}


extension TableMacroRuntimeTests {

    func testTable_createStatementFromColumnDeclaration() {
        // given
        self.waitOpenDatabase()

        // when
        let statement = MacroTestTable.createStatement

        // then
        XCTAssertEqual(
            statement,
            "CREATE TABLE IF NOT EXISTS macro_users ("
                + "uid TEXT , name TEXT NOT NULL, age INTEGER, "
                + "email TEXT UNIQUE NOT NULL, phone TEXT, intro TEXT,"
                + "PRIMARY KEY (uid));"
        )
    }

    func testTable_insertAndLoadEntity_keepTextColumnsInDeclarationOrder() {
        // given
        self.waitOpenDatabase()
        _ = self.service.run { try $0.createTableOrNot(MacroTestTable.self) }

        // when
        _ = self.service.run { try $0.insertOne(MacroTestTable.self, entity: self.dummyUser, shouldReplace: true) }
        let query = MacroTestTable.selectAll { $0.uid == "uid:1" }
        let loaded = try? self.service.run { try $0.loadOne(MacroTestTable.self, query: query) }.get()

        // then
        XCTAssertEqual(loaded?.uid, "uid:1")
        XCTAssertEqual(loaded?.name, "name")
        XCTAssertEqual(loaded?.age, 30)
        XCTAssertEqual(loaded?.email, "email@some.com")
        XCTAssertEqual(loaded?.phone, "010-0000-0000")
        XCTAssertEqual(loaded?.introduction, "intro text")
    }

    func testTable_selectSomeColumnsWithMapping() {
        // given
        self.waitOpenDatabase()
        _ = self.service.run { try $0.createTableOrNot(MacroTestTable.self) }
        _ = self.service.run { try $0.insertOne(MacroTestTable.self, entity: self.dummyUser, shouldReplace: true) }

        // when
        let query = MacroTestTable.selectSome { [$0.name, $0.email] }
        let mapping: (CursorIterator) throws -> (String, String) = { cursor in
            return (try cursor.next().unwrap(), try cursor.next().unwrap())
        }
        let pairs = try? self.service.run { try $0.load(query, mapping: mapping) }.get()

        // then
        XCTAssertEqual(pairs?.first?.0, "name")
        XCTAssertEqual(pairs?.first?.1, "email@some.com")
    }

    func testTable_migrateWithOverridenMigrateStatement() {
        // given
        let expect = expectation(description: "migrate macro generated table")
        self.waitOpenDatabase()
        _ = self.service.run { try $0.createTableOrNot(MacroTestTable.self) }
        _ = self.service.run { try $0.insertOne(MacroTestTable.self, entity: self.dummyUser, shouldReplace: true) }

        // when
        self.service.migrate(upto: 1, steps: { version, database in
            try? database.migrate(MacroTestTableV1.self, version: version)
        }) { _ in
            expect.fulfill()
        }
        self.wait(for: [expect], timeout: self.timeout)

        // then
        let updateQuery = MacroTestTableV1.update { [$0.isBlocked == true] }.where { $0.uid == "uid:1" }
        _ = self.service.run { try $0.update(MacroTestTableV1.self, query: updateQuery) }

        let query = MacroTestTableV1.selectAll { $0.uid == "uid:1" }
        let migrated = try? self.service.run { try $0.loadOne(MacroTestTableV1.self, query: query) }.get()
        XCTAssertEqual(migrated?.isBlocked, true)
        XCTAssertEqual(migrated?.introduction, "intro text")
    }
}

extension TableMacroRuntimeTests {

    func testEntity_buildWithoutOptionalArgumentsThenMutate() {
        // given
        self.waitOpenDatabase()
        _ = self.service.run { try $0.createTableOrNot(MacroTestTable.self) }
        var entity = MacroTestTable.Entity(uid: "uid:2", name: "name", email: "email2@some.com")

        // when
        entity.phone = "010-1111-1111"
        entity.introduction = "filled later"
        _ = self.service.run { try $0.insertOne(MacroTestTable.self, entity: entity, shouldReplace: true) }

        // then
        let query = MacroTestTable.selectAll { $0.uid == "uid:2" }
        let loaded = try? self.service.run { try $0.loadOne(MacroTestTable.self, query: query) }.get()
        XCTAssertEqual(loaded?.age, nil)
        XCTAssertEqual(loaded?.phone, "010-1111-1111")
        XCTAssertEqual(loaded?.introduction, "filled later")
    }
}
