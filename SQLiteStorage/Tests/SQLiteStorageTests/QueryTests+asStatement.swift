//
//  QueryTests.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import XCTest

@testable import SQLiteStorage



class QueryTests: XCTestCase { }


// MARK: - test query to statement

extension QueryTests {
    
    func testQuery_convertToSelectStatement_fromTable() {
        // given
        let table = Dummies.Table1.self
        
        // when
        let queries: [SelectQuery<Dummies.Table1>] = [
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
            "SELECT * FROM Table1;",
            "SELECT * FROM Table1 WHERE k1 = 1 AND k2 > 2;",
            "SELECT * FROM Table1 WHERE (k1 = 1 AND k2 > 2) OR k1 NOT IN (2, 3, 4);",
            "SELECT k1, k2 FROM Table1;",
            "SELECT k2 FROM Table1 WHERE k2 != 100;",
        ])
    }
    
    func testQuery_convertToUpdateStatement_fromTable() {
        // given
        let table = Dummies.Table1.self
        
        // when
        let queries: [UpdateQuery<Dummies.Table1>] = [
            table.update{ [$0.k1 == 10, $0.k2 > 10, $0.k2 == 100] },
            table.update{ [$0.k2 == 10] }
                .where{ $0.k2 > 10 }
        ]
        let statements = queries.compactMap{ try? $0.asStatement() }
        
        // then
        XCTAssertEqual(statements, [
            "UPDATE Table1 SET k1 = 10, k2 = 100;",
            "UPDATE Table1 SET k2 = 10 WHERE k2 > 10;",
        ])
    }
    
    func testQuery_convertToDeleteStatement_fromTable() {
        // given
        let table = Dummies.Table1.self
        
        // when
        let queries: [DeleteQuery<Dummies.Table1>] = [
            table.delete(),
            table.delete().where{ $0.k2 == 100 }
        ]
        let statements = queries.compactMap{ try? $0.asStatement() }
        
        // then
        XCTAssertEqual(statements, [
            "DELETE FROM Table1;",
            "DELETE FROM Table1 WHERE k2 = 100;"
        ])
    }
}


// MARK: - test join query

extension QueryTests {
    
    func testQuery_makeInnerJoinQueryStatement_byCombineSingleQueries() {
        // given
        let (left, right) = (Dummies.Table1.self, Dummies.Table2.self)
        
        let leftQry = left.selectAll().where{ $0.k1 == 1 }.limit(10)
        let rightQry = right.selectSome{ [$0.c1, $0.c2] }.where{ $0.c2 > 10 }
        
        // when
        let joinQuery = leftQry.innerJoin(with: rightQry) { ($0.k1, $1.c2) }
        let stmt = try? joinQuery.asStatement()
        
        // then
        XCTAssertEqual(stmt, "SELECT Table1.*, Table2.c1, Table2.c2 FROM Table1 INNER JOIN Table2 ON Table1.k1 = Table2.c2 WHERE Table1.k1 = 1 AND Table2.c2 > 10 LIMIT 10;")
    }
}
