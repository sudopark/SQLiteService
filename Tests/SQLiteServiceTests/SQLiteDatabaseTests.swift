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
    
    private var dummyModels: [Dummies.TypesModel] {
        return (0..<10).map { int -> Dummies.TypesModel in
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
            try self.database.insert(self.table, models: self.dummyModels, shouldReplace: true)
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
            try self.database.insert(self.table, models: self.dummyModels, shouldReplace: true)
            inserted = true
        } catch {}
        
        // then
        XCTAssertEqual(inserted, true)
    }
    
    private func prepareSavedDatas() {
        self.openDataBase()
        try? self.database.insert(self.table, models: self.dummyModels, shouldReplace: true)
    }
    
    func testDatabase_loadInsertedDatas() {
        // given
        self.prepareSavedDatas()
        var models: [Dummies.TypesModel]?
        
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
        var models: [Dummies.TypesModel]?
        
        let mapping: (CursorIterator) throws -> Dummies.TypesModel = { cursor in
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
        var model5: Dummies.TypesModel?
        
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
        var models: [Dummies.TypesModel]?
        
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
}
