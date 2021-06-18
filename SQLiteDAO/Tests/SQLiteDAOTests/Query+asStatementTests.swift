//
//  QueryTests.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import XCTest

@testable import SQLiteDAO



class QueryTests: XCTestCase { }


// MARK: - test query to statement

extension QueryTests {
    
    func testQuery_convertToSelectStatement_fromTable() {
        // given
        let table = DummyTable()
        
        // when
        let queries: [SelectQuery<DummyTable>] = [
            table.selectAll(),
            table.selectAll()
                .where { $0.k1 == 1 && $0.k2 > 2 },
            table.selectAll()
                .where { ($0.k1 == 1 && $0.k2 > 2) || $0.k1.notIn([2, 3, 4]) },
            table.selectSome{ [$0.k1, $0.k2] },
            table.selectSome{ [$0.k2] }
                .where{ $0.k2 != 100 }
        ]
        let statements = queries.compactMap{ try? $0.asStatement() }
        
        // then
        XCTAssertEqual(statements, [
            "SELECT * FROM Dummy;",
            "SELECT * FROM Dummy WHERE k1 = 1 AND k2 > 2;",
            "SELECT * FROM Dummy WHERE (k1 = 1 AND k2 > 2) OR k1 NOT IN (2, 3, 4);",
            "SELECT k1, k2 FROM Dummy;",
            "SELECT k2 FROM Dummy WHERE k2 != 100;",
        ])
    }
    
    func testQuery_convertToUpdateStatement_fromTable() {
        // given
        let table = DummyTable()
        
        // when
        let queries: [UpdateQuery<DummyTable>] = [
            table.update{ [$0.k1 == 10, $0.k2 > 10, $0.k2 == 100] },
            table.update{ [$0.k2 == 10] }
                .where{ $0.k2 > 10 }
        ]
        let statements = queries.compactMap{ try? $0.asStatement() }
        
        // then
        XCTAssertEqual(statements, [
            "UPDATE Dummy SET k1 = 10, k2 = 100;",
            "UPDATE Dummy SET k2 = 10 WHERE k2 > 10;",
        ])
    }
    
    func testQuery_convertToDeleteStatement_fromTable() {
        // given
        let table = DummyTable()
        
        // when
        let queries: [DeleteQuery<DummyTable>] = [
            table.delete(),
            table.delete().where{ $0.k2 == 100 }
        ]
        let statements = queries.compactMap{ try? $0.asStatement() }
        
        // then
        XCTAssertEqual(statements, [
            "DELETE FROM Dummy;",
            "DELETE FROM Dummy WHERE k2 = 100;"
        ])
    }
}


// MARK: - test join query

extension QueryTests {
    
    func testQuery_makeInnerJoinQueryStatement_byCombineSingleQueries() {
        // given
        let (left, right) = (DummyTable(), Table2())
        
        let leftQry = left.selectAll().where{ $0.k1 == 1 }.limit(10)
        let rightQry = right.selectSome{ [$0.c1, $0.c2] }.where{ $0.c2 > 10 }
        
        // when
        let joinQuery = leftQry.innerJoin(with: rightQry) { ($0.k1, $1.c2) }
        let stmt = try? joinQuery.asStatement()
        
        // then
        XCTAssertEqual(stmt, "SELECT Dummy.*, T2.c1, T2.c2 FROM Dummy INNER JOIN T2 ON Dummy.k1 = T2.c2 WHERE Dummy.k1 = 1 AND T2.c2 > 10 LIMIT 10;")
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
    
    struct Table2: Table {
        
        static var tableName: String { "T2" }
        
        enum Column: String, TableColumn {
            case c1
            case c2
            
            var dataType: ColumnDataType { .integer([]) }
        }
        
        typealias ColumnType = Column
        typealias Model = DummyModel
        
        func serialize(model: QueryTests.DummyModel) throws -> [StorageDataType?] { [] }
        
        func deserialize(cursor: OpaquePointer?) throws -> QueryTests.DummyModel {
            return .init(k1: 0, k2: "")
        }
    }
}
