//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import Foundation


private extension StorageDataType {
    
    func convert() -> String {
        switch self {
        case let string as String:
            let replaceSingleQuote = string.replacingOccurrences(of: "'", with: "''")
            return "'\(replaceSingleQuote)'"
            
        case let bool as Bool:
            return bool ? "1" : "0"
            
        default:
            return "\(self)"
        }
    }
}


private extension Optional where Wrapped == StorageDataType {
    
    func asStatementText() -> String {
        switch self {
        case .none: return "NULL"
        case let .some(value): return value.convert()
        }
    }
}


extension QueryStatement.Condition {
    
    func asStatementText() throws -> String {
        switch self.operation {
        case .equal:
            return "\(self.key) = \(self.value.asStatementText())"
            
        case .notEqual:
            return "\(self.key) != \(self.value.asStatementText())"
            
        case let .greaterThan(orEqual):
            return "\(self.key) \(orEqual ? ">=" : ">") \(self.value.asStatementText())"
            
        case let .lessThan(orEqual):
            return "\(self.key) \(orEqual ? "<=" : "<") \(self.value.asStatementText())"
            
        case .in:
            guard let array = self.value as? [StorageDataType] else {
                throw SQliteErrors.invalidArgument("not a array")
            }
            let arrayText = array.map{ $0.convert() }.joined(separator: ", ")
            return "\(self.key) IN (\(arrayText))"
            
        case .notIn:
            guard let array = self.value as? [StorageDataType] else {
                throw SQliteErrors.invalidArgument("not a array")
            }
            let arrayText = array.map{ $0.convert() }.joined(separator: ", ")
            return "\(self.key) NOT IN (\(arrayText))"
        }
    }
}


extension QueryStatement.ConditionSet {
    
    func asStatementText() throws -> String {
        
        switch self {
        case .empty:
            return ""
            
        case let .single(expr):
            return try expr.asStatementText()
            
        case let .and(left, right, capsuled):
            let text = "\(try left.asStatementText()) AND \(try right.asStatementText())"
            return capsuled ? "(\(text))" : text
            
        case let .or(left, right, capsuled):
            let text = "\(try left.asStatementText()) OR \(try right.asStatementText())"
            return capsuled ? "(\(text))" : text
            
        }
    }
}


extension SelectQuery.SelectionType {
    
    private var singleSelectColumn: String {
        switch self {
        case .all: return "*"
        case let .some(columns, _) where columns.count == 1:
            return columns[0]
            
        default: return ""
        }
    }
    
    private var table: String {
        switch self {
        case let .all(table),
             let .some(_, table),
             let .someAt(_, table): return table
        }
    }
    
    func asStatementText() -> String {
        switch self {
        case let .all(table):
            return "SELECT * FROM \(table)"
        case let .some(columns, table):
            return "SELECT \(columns.joined(separator: ", ")) FROM \(table)"
        case let .someAt(pairs, table):
            let text = pairs.map {  "\($0.table).\($0.singleSelectColumn)" }.joined(separator: ", ")
            return "SELECT \(text) FROM \(table)"
        }
    }
}

extension SelectQuery {
    
    func asStatement() throws -> String {
        var sender = self.selection.asStatementText()
        let condition = try self.conditions.asStatementText()
        if condition.isEmpty == false {
            sender = "\(sender) WHERE \(condition)"
        }
        
        let ascString = ascendings.map{ "\($0) ASC" }.joined(separator: ", ")
        let descString = descendings.map{ "\($0) DESC" }.joined(separator: ", ")
        
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
