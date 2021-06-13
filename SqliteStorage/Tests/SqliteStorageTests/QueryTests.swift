//
//  QueryTests.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import XCTest

@testable import SqliteStorage



class QueryTests: XCTestCase { }


extension QueryTests {
    
    func testQuery_convertToStatement_fromBuilder() {
        // given
        let builder = QueryBuilder(.select(.all(from: "Some")))
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
    
    func testQuery_convertToStatement_fromBuilderWithSomeColumns() {
        // given
        let builder = QueryBuilder(.select(.some(["c1", "c2"], from: "Some")))
        
        // when
        let query = builder.build()
        let stmt = try? query.asStatement()
        
        // then
        XCTAssertEqual(stmt, "SELECT c1, c2 FROM Some;")
    }
    
    func testQuery_convertToStatement_fromTable() {
        // given
        let table = DummyTable()
        
        // when
        let queries: [Query] = [
            table.selectAll(),
            table.selectAll{ $0.k1 == 1 && $0.k2 > 2 },
            table.selectAll{
                ($0.k1 == 1 && $0.k2 > 2) || $0.k1.notIn([2, 3, 4])
            }
        ]
        let statements = queries.compactMap{ try? $0.asStatement() }
        
        // then
        XCTAssertEqual(statements, [
            "SELECT * FROM Dummy;",
            "SELECT * FROM Dummy WHERE k1 = 1 AND k2 > 2;",
            "SELECT * FROM Dummy WHERE (k1 = 1 AND k2 > 2) OR k1 NOT IN (2, 3, 4);",
        ])
    }
}


extension QueryTests {
    
    struct DummyModel {
        let k1: Int
        let k2: String
    }
    
    struct DummyTable: Table {
        
        static var tableName: String { "Dummy" }
        
        enum Columns: String, TableColumn {
            
            case k1
            case k2
            
            var dataType: ColumnDataType {
                switch self {
                case .k1: return .integer([])
                case .k2: return .text([])
                }
            }
        }
        
        typealias Model = DummyModel
        typealias ColumnType = Columns
        
        func serialize(model: QueryTests.DummyModel) throws -> [StorageDataType?] {
            return [model.k1, model.k2]
        }
        
        func deserialize(cursor: OpaquePointer?) throws -> QueryTests.DummyModel {
            guard let cursor = cursor else {
                throw SQLiteErrors.step("deserialize")
            }
            let int: Int = try cursor[0].unwrap()
            let str: String = try cursor[1].unwrap()
            return .init(k1: int, k2: str)
        }
    }
}
