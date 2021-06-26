//
//  SQLIteConnectionTests.swift
//  
//
//  Created by sudo.park on 2021/06/19.
//

import XCTest

@testable import SQLiteStorage


class SQLIteConnectionTests: XCTestCase {
    
    var dbPath: String!
    var table: Dummies.TypesTable.Type!
    var connection: SQLiteDataBase!
    
    override func setUpWithError() throws {
        
        let dbName = "Test.db"
        self.table = Dummies.TypesTable.self
        let path = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                        .appendingPathComponent(dbName)
                        .path
        self.dbPath = path
        self.connection = .init()
    }
    
    override func tearDownWithError() throws {
        try? self.connection.close()
        try? FileManager.default.removeItem(atPath: self.dbPath)
        self.connection = nil
        self.table = nil
        self.dbPath = nil
    }
}


extension SQLIteConnectionTests {
    
    // open
    func testConnection_open() {
        // given
        var isOpened = false
        
        // when
        do {
            try self.connection.open(path: dbPath)
            isOpened = true
        } catch {}
        
        // then
        XCTAssertEqual(isOpened, true)
    }
    
    func testConnection_OpenAndClose() {
        // given
        var isClosed = false
        
        // when
        do {
            try self.connection.open(path: self.dbPath)
            try self.connection.close()
            isClosed = true
        } catch {}
        
        // then
        XCTAssertEqual(isClosed, true)
    }
    
    func testConnection_whenCloseNotOpenedConnection_error() {
        // given
        var closeError: Error?
        
        // when
        do {
            try self.connection.close()
        } catch let error {
            closeError = error
        }
        
        // then
        XCTAssertNotNil(closeError)
    }
    
    private func openDataBase() {
        try? self.connection.open(path: self.dbPath)
    }
    
    // create table
    func testConnection_createTable() {
        // given
        var isCreated = false
        self.openDataBase()
        
        // when
        do {
            try self.connection.createTableOrNot(self.table)
            isCreated = true
        } catch { }
        
        // then
        XCTAssertEqual(isCreated, true)
    }
    
    // drop
    
    func testConnection_dropExistingTable() {
        // given
        var isDroped = false
        self.openDataBase()
        
        // when
        do {
            try self.connection.createTableOrNot(self.table)
            try self.connection.dropTable(self.table)
            isDroped = true
        }catch {}
        
        // then
        XCTAssertEqual(isDroped, true)
    }
}


extension SQLIteConnectionTests {
    
    private var dummyModels: [Dummies.TypesModel] {
        return (0..<10).map { int -> Dummies.TypesModel in
            return .init(primaryInt: int, int: nil, real: nil, text: nil, bool: nil, notnull: int, withDefault: "\(int)")
        }
    }
    
    func testConnection_insertModels() {
        // given
        self.openDataBase()
        try? self.connection.createTableOrNot(self.table)
        var inserted: Bool = false
        
        // when
        do {
            try self.connection.insert(self.table, models: self.dummyModels, shouldReplace: true)
            inserted = true
        } catch {}
        
        // then
        XCTAssertEqual(inserted, true)
    }
    
    func testConnection_whenInsertDataAtNoExistingTable_createTableAndSave() {
        // given
        self.openDataBase()
        var inserted: Bool = false
        
        // when
        do {
            try self.connection.insert(self.table, models: self.dummyModels, shouldReplace: true)
            inserted = true
        } catch {}
        
        // then
        XCTAssertEqual(inserted, true)
    }
    
    private func prepareSavedDatas() {
        self.openDataBase()
        try? self.connection.insert(self.table, models: self.dummyModels, shouldReplace: true)
    }
    
    func testConnection_loadInsertedDatas() {
        // given
        self.prepareSavedDatas()
        var models: [Dummies.TypesModel]?
        
        // when
        do {
            let query = self.table.selectAll()
            models = try self.connection.load(self.table, query: query)
        } catch { }
        
        // then
        XCTAssertEqual(models?.count, 10)
    }
    
    func testConnection_updateSavedValue() {
        // given
        self.prepareSavedDatas()
        var model5: Dummies.TypesModel?
        
        // when
        do {
            let updateQuery = self.table.update(replace: { [$0.int == 100] })
            try self.connection.update(self.table, query: updateQuery)
            
            let selectQuery = self.table.selectAll().where{ $0.primaryInt == 5 }
            model5 = try self.connection.load(self.table, query: selectQuery).first

        } catch {}
        
        // then
        XCTAssertEqual(model5?.int, 100)
    }
    
    func testConnection_deleteSavedModels() {
        // given
        self.prepareSavedDatas()
        var models: [Dummies.TypesModel]?
        
        // when
        do {
            let deleteQuery = self.table.delete().where{ $0.primaryInt == 5 }
            try self.connection.delete(self.table, query: deleteQuery)
            
            let selectQuery = self.table.selectAll()
            models = try self.connection.load(self.table, query: selectQuery)
        } catch { }
        
        // then
        XCTAssertEqual(models?.count, 9)
        XCTAssertNil(models?.first(where: { $0.primaryInt == 5 }))
    }
}
