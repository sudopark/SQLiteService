//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/19.
//

import Foundation

public struct UpdateQuery<T: Table>: Query, QueryBuilable {
    
    private let replaceSets: [QueryExpression.ReplaceSet]
    public var builder: QueryBuilder
    
    init(_ replaces: [QueryExpression.ReplaceSet]) {
        self.replaceSets = replaces
        self.builder = .init()
    }
}


extension UpdateQuery {
    
    public func asStatement() throws -> String {
        
        let prefix = "UPDATE \(T.tableName)"
        let setString = self.replaceSets
            .map{ "\($0.column) = \($0.value.asStatementText())" }
            .joined(separator: ", ")
        
        var stmt = "\(prefix) SET \(setString)"
        stmt = try self.builder.appendConditionText(stmt)
        
        return "\(stmt);"
    }
}
