//
//  SelectQueryBuilderTests.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import XCTest

@testable import SqliteStorage



class SelectQueryBuilderTests: XCTestCase { }


extension SelectQueryBuilderTests {
    
    func testBuilder_build() {
        // given
        let builder: SelectQueryBuilder = .init(.all(from: "T"))
        
        // when
        let query = builder.build()
        
        // then
        XCTAssertEqual(query.selection.identifier, "all:T")
        XCTAssertEqual(query.conditions, .empty)
        XCTAssertEqual(query.ascendings, [])
        XCTAssertEqual(query.descendings, [])
        XCTAssertEqual(query.limit, nil)
    }
    
    func testBuilder_buildWithConditions() {
        // given
        let builder: SelectQueryBuilder = .init(.all(from: "T"))
        
        // when
        let condition: QueryStatement.Condition = .init(key: "some", operation: .equal, value: 1)
        let query = builder
            .where(condition.and(condition))
            .where(condition)
            .build()
        
        // then
        XCTAssertEqual(query.selection.identifier, "all:T")
        XCTAssertEqual(query.conditions, .and(.and(.single(condition), .single(condition), capsuled: true), .single(condition), capsuled: false))
        XCTAssertEqual(query.ascendings, [])
        XCTAssertEqual(query.descendings, [])
        XCTAssertEqual(query.limit, nil)
    }
    
    func testBuilder_buildWithOrdersAndLimit() {
        // given
        let builder: SelectQueryBuilder = .init(.all(from: "T"))
        
        // when
        let condition: QueryStatement.Condition = .init(key: "some", operation: .equal, value: 1)
        let query = builder
            .where(condition.and(condition))
            .where(condition)
            .orderBy("k1", isAscending: true)
            .orderBy("k2", isAscending: false)
            .limit(100)
            .build()
        
        // then
        XCTAssertEqual(query.selection.identifier, "all:T")
        XCTAssertEqual(query.conditions, .and(.and(.single(condition),
                                                   .single(condition), capsuled: true),
                                              .single(condition), capsuled: false))
        XCTAssertEqual(query.ascendings, ["k1"])
        XCTAssertEqual(query.descendings, ["k2"])
        XCTAssertEqual(query.limit, 100)
    }
}


extension SelectQueryBuilderTests {
    
    func testBuilder_makeQueryAndconvertToString() {
        // given
        let builder = SelectQueryBuilder(.all(from: "Some"))
        let unit: QueryStatement.Condition = .init(key: "k", operation: .equal, value: "v")
        
        // when
        let query = builder
            .where(unit)
            .orderByRowID(isAscending: true)
            .orderBy("k2", isAscending: false)
            .limit(100)
            .build()
        let stmt = try? query.asStatement()
        
        // then
        XCTAssertEqual(stmt, "SELECT * FROM Some WHERE k = 'v' ORDER BY rowid ASC, k2 DESC LIMIT 100;")
    }
    
    func testBuilder_selectSomeColumns_toString() {
        // given
        let builder = SelectQueryBuilder(.some(["c1", "c2"], from: "Some"))
        
        // when
        let query = builder.build()
        let stmt = try? query.asStatement()
        
        // then
        XCTAssertEqual(stmt, "SELECT c1, c2 FROM Some;")
    }
}



private extension SelectQuery.SelectionType {
    
    var identifier: String {
        switch self {
        case let .all(from): return "all:\(from)"
        case let .some(_, from): return "some:\(from)"
        case let .someAt(_, from): return "someAt:\(from)"
        }
    }
}
