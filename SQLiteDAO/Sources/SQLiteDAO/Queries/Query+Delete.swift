//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/19.
//

import Foundation


public struct DeleteQuery<T: Table>: Query, QueryBuilable {
    
    public var builder: QueryBuilder
    
    init() {
        self.builder = .init()
    }
}


extension DeleteQuery {
    
    public func asStatement() throws -> String {
        
        var stmt = "DELETE FROM \(T.tableName)"
        stmt = try self.builder.appendConditionText(stmt)
        
        return "\(stmt);"
    }
}
