//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/19.
//

import Foundation


public struct SelectQuery<T: Table>: Query, QueryBuilable {
    
    let selection: QueryExpression.Selection
    public var builder: QueryBuilder
    
    init(_ selection: QueryExpression.Selection) {
        self.selection = selection
        self.builder = .init()
    }
}

extension SelectQuery {
    
    public func asStatement() throws -> String {
        
        var stmt = self.selection.asStatementText(T.tableName)
        stmt = try self.builder.appendConditionText(stmt)
        stmt = self.builder.appendOrderText(stmt)
        stmt = self.builder.appendLimitText(stmt)
        
        return "\(stmt);"
    }
}


extension QueryExpression.Selection {
    
    func asStatementText(_ table: TableName) -> String {
        switch self {
        case .all:
            return "SELECT * FROM \(table)"
        case let .some(columns):
            return "SELECT \(columns.joined(separator: ", ")) FROM \(table)"
        }
    }
}
