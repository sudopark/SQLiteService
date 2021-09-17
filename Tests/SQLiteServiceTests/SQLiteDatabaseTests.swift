//
//  SQLiteDatabaseTests.swift
//  
//
//  Created by sudo.park on 2021/06/19.
//

import XCTest

@testable import SQLiteService


class SQLiteDatabaseTests: XCTestCase {
    
    var dbPath: String!
    var table: Dummies.TypesTable.Type!
    var database: SQLiteDataBase!
    
    override func setUpWithError() throws {
        
        let dbName = "Test.db"
        self.table = Dummies.TypesTable.self
        let path = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                        .appendingPathComponent(dbName)
                        .path
        self.dbPath = path
        self.database = .init()
    }
    
    override func tearDownWithError() throws {
        try? self.database.close()
        try? FileManager.default.removeItem(atPath: self.dbPath)
        self.database = nil
        self.table = nil
        self.dbPath = nil
    }
}


extension SQLiteDatabaseTests {
    
    // open
    func testDatabase_open() {
        // given
        var isOpened = false
        
        // when
        do {
            try self.database.open(path: dbPath)
            isOpened = true
        } catch {}
        
        // then
        XCTAssertEqual(isOpened, true)
    }
    
    func testDatabase_OpenAndClose() {
        // given
        var isClosed = false
        
        // when
        do {
            try self.database.open(path: self.dbPath)
            try self.database.close()
            isClosed = true
        } catch {}
        
        // then
        XCTAssertEqual(isClosed, true)
    }
    
    func testDatabase_whenCloseNotOpenedConnection_error() {
        // given
        var closeError: Error?
        
        // when
        do {
            try self.database.close()
        } catch let error {
            closeError = error
        }
        
        // then
        XCTAssertNotNil(closeError)
    }
    
    private func openDataBase() {
        try? self.database.open(path: self.dbPath)
    }
    
    // create table
    func testDatabase_createTable() {
        // given
        var isCreated = false
        self.openDataBase()
        
        // when
        do {
            try self.database.createTableOrNot(self.table)
            isCreated = true
        } catch { }
        
        // then
        XCTAssertEqual(isCreated, true)
    }
    
    // drop
    
    func testDatabase_dropExistingTable() {
        // given
        var isDroped = false
        self.openDataBase()
        
        // when
        do {
            try self.database.createTableOrNot(self.table)
            try self.database.dropTable(self.table)
            isDroped = true
        }catch {}
        
        // then
        XCTAssertEqual(isDroped, true)
    }
}


extension SQLiteDatabaseTests {
    
    private var dummyEntities: [Dummies.TypesEntity] {
        return (0..<10).map { int -> Dummies.TypesEntity in
            return .init(primaryInt: int, int: nil, real: nil, text: nil, bool: nil, notnull: int, withDefault: "\(int)")
        }
    }
    
    func testDatabase_insertModels() {
        // given
        self.openDataBase()
        try? self.database.createTableOrNot(self.table)
        var inserted: Bool = false
        
        // when
        do {
            try self.database.insert(self.table, entities: self.dummyEntities, shouldReplace: true)
            inserted = true
        } catch {}
        
        // then
        XCTAssertEqual(inserted, true)
    }
    
    func testDatabase_whenInsertDataAtNoExistingTable_createTableAndSave() {
        // given
        self.openDataBase()
        var inserted: Bool = false
        
        // when
        do {
            try self.database.insert(self.table, entities: self.dummyEntities, shouldReplace: true)
            inserted = true
        } catch {}
        
        // then
        XCTAssertEqual(inserted, true)
    }
    
    private func prepareSavedDatas() {
        self.openDataBase()
        try? self.database.insert(self.table, entities: self.dummyEntities, shouldReplace: true)
    }
    
    func testDatabase_loadInsertedDatas() {
        // given
        self.prepareSavedDatas()
        var models: [Dummies.TypesEntity]?
        
        // when
        do {
            let query = self.table.selectAll()
            models = try self.database.load(self.table, query: query)
        } catch { }
        
        // then
        XCTAssertEqual(models?.count, 10)
    }
    
    func testDatabase_loadDataAndMapping() {
        // given
        self.prepareSavedDatas()
        var models: [Dummies.TypesEntity]?
        
        let mapping: (CursorIterator) throws -> Dummies.TypesEntity = { cursor in
            return try .init(cursor)
        }
        
        // when
        do {
            let query = self.table.selectAll()
            models = try self.database.load(query, mapping: mapping)
        } catch { }
        
        // then
        XCTAssertEqual(models?.count, 10)
    }
    
    func testDatabase_updateSavedValue() {
        // given
        self.prepareSavedDatas()
        var model5: Dummies.TypesEntity?
        
        // when
        do {
            let updateQuery = self.table.update(replace: { [$0.int == 100] })
            try self.database.update(self.table, query: updateQuery)
            
            let selectQuery = self.table.selectAll().where{ $0.primaryInt == 5 }
            model5 = try self.database.load(self.table, query: selectQuery).first

        } catch {}
        
        // then
        XCTAssertEqual(model5?.int, 100)
    }
    
    func testDatabase_deleteSavedModels() {
        // given
        self.prepareSavedDatas()
        var models: [Dummies.TypesEntity]?
        
        // when
        do {
            let deleteQuery = self.table.delete().where{ $0.primaryInt == 5 }
            try self.database.delete(self.table, query: deleteQuery)
            
            let selectQuery = self.table.selectAll()
            models = try self.database.load(self.table, query: selectQuery)
        } catch { }
        
        // then
        XCTAssertEqual(models?.count, 9)
        XCTAssertNil(models?.first(where: { $0.primaryInt == 5 }))
    }
    
    func testDatabase_tableHasMulitplePrimaryKey() {
        // given
        self.openDataBase()
        
        let table = Dummies.DoubleKeyTable.self
        typealias Entity = Dummies.DoubleKeyTable.Entity
        
        let e11 = Entity(k1: 1, k2: 1)
        let e12 = Entity(k1: 1, k2: 2)
        let e21 = Entity(k1: 2, k2: 1)
        let e22 = Entity(k1: 2, k2: 2)
        
        let entities = [e11, e12, e21, e22]
        try? self.database.insert(table, entities: entities)
        
        // when
        let newE12 = Entity(k1: 1, k2: 2, rand: "new")
        try? self.database.insert(table, entities: [newE12], shouldReplace: false)
        
        // then
        let query = table.selectAll()
        let loadedEntities = try? self.database.load(table, query: query)
        XCTAssertEqual(loadedEntities?.count, 4)
        XCTAssertEqual(loadedEntities?.first(where: { $0.k1 == 1 && $0.k2 == 2})?.rand, e12.rand)
    }
    
    func testDatabase_loadIsNull() {
        // given
        self.openDataBase()
        let items: [Dummies.TypesEntity] = [
            .init(primaryInt: 0, int: 0, real: 0, text: nil, bool: nil, notnull: 0, withDefault: ""),
            .init(primaryInt: 1, int: nil, real: 1, text: nil, bool: nil, notnull: 1, withDefault: ""),
            .init(primaryInt: 2, int: nil, real: 2, text: nil, bool: nil, notnull: 2, withDefault: ""),
        ]
        try? self.database.insert(self.table, entities: items)
        
        var intNullModels: [Dummies.TypesEntity]?
        
        // when
        do {
            let selectQuery = self.table.selectAll { $0.int.isNull() }
            intNullModels = try self.database.load(self.table, query: selectQuery)

        } catch {}
        
        // then
        XCTAssertEqual(intNullModels?.map{ $0.primaryInt }, [1, 2])
        XCTAssertEqual(intNullModels?.map{ $0.int }, [nil, nil])
    }
}
