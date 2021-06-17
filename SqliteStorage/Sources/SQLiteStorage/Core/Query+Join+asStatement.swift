//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/18.
//

import Foundation


private extension QueryExpression.Method.Selection {
    
    func selectedColumnTexts(on table: TableName) -> [String] {
        switch self {
        case .all:
            return ["\(table).*"]
            
        case let .some(columns):
            return columns.map{ "\(table).\($0)"}
        }
    }
}

private extension JoinExpression.On {
    
    func asStatement(left table: TableName) -> String {
        let (left, right) = (table, self.table)
        return "\(self.method.rawValue) JOIN \(right) ON \(left).\(self.match.left) = \(right).\(match.right)"
    }
}

extension JoinQuery: Query {
    
    public func asStatement() throws -> String {
        
        let selectedColumnTexts = self.selections
            .flatMap{ $0.selection.selectedColumnTexts(on: $0.table) }.joined(separator: ", ")
        
        var sender = "SELECT \(selectedColumnTexts) FROM \(T.tableName)"
        
        let onTexts = self.joinOns.map{ $0.asStatement(left: T.tableName) }.joined(separator: ", ")
        sender = "\(sender) \(onTexts)"
        
        let condition = try self.conditionSet.asStatementText()
        if condition.isEmpty == false {
            sender = "\(sender) WHERE \(condition)"
        }
        
        let ascString = ascendings.map{ "\($0.table).\($0.column) ASC" }.joined(separator: ", ")
        let descString = descendings.map{ "\($0.table).\($0.column) DESC" }.joined(separator: ", ")
        
        let orderString = ascString.isEmpty ? descString : descString.isEmpty
            ? ascString : "\(ascString), \(descString)"
        if orderString.isEmpty == false {
            sender = "\(sender) ORDER BY \(orderString)"
        }
        
        if let limit = self.limit {
            sender = "\(sender) LIMIT \(limit)"
        }
        return "\(sender);"
    }
}
