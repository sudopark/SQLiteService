//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/21.
//

import Foundation

import RxSwift

@testable import RxSQLiteStorage


class SQLiteStorageTests_Rx: BaseSQLiteStorageTests {
    
    var disposeBag: DisposeBag!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        self.disposeBag = .init()
    }
    
    override func tearDownWithError() throws {
        self.disposeBag = nil
        try super.tearDownWithError()
    }
}


extension SQLiteStorageTests_Rx {
    
    
    func testStorage_open() {
        // given
        let expect = expectation(description: "open database")
        
        // when
        self.storage.rx.open(path: self.dbPath)
            .subscribe(onSuccess: expect.fulfill)
            .disposed(by: self.disposeBag)
        
        // then
        self.wait(for: [expect], timeout: self.timeout)
    }
    
    func testStorage_openAndClose() {
        // given
        let expect = expectation(description: "open and close database")
        let table = UserTable.self
        
        // when
        let open = self.storage.rx.open(path: self.dbPath)
        let andSaveSomeData = self.storage.rx.run(execute: { try $0.insert(table, models: self.dummyUsers) })
        let thenClose = self.storage.rx.close()
        
        open.flatMap{ _ in andSaveSomeData }.flatMap{ _ in thenClose }
            .subscribe(onSuccess: expect.fulfill)
            .disposed(by: self.disposeBag)
        
        // then
        self.wait(for: [expect], timeout: self.timeout)
    }
    
    func testStorage_whenSyncAfterAsync_shouldNotDeadlock() {
        // given
        let expect = expectation(description: "open and close database")
        let table = UserTable.self
        
        // when
        let asyncOpen = self.storage.rx.open(path: self.dbPath )
        let doSyncJob: () -> Single<Void> = {
            self.storage.run(execute: { try $0.createTableOrNot(table) })
            return .just(())
        }
        asyncOpen.flatMap(doSyncJob)
            .subscribe(onSuccess: expect.fulfill)
            .disposed(by: self.disposeBag)
        
        // then
        self.wait(for: [expect], timeout: self.timeout)
    }
}
