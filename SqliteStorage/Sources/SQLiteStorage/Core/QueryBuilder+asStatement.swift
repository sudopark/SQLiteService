//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import Foundation


extension StorageDataType {
    
    func toString() -> String {
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


extension Optional where Wrapped == StorageDataType {
    
    func asStatementText() -> String {
        switch self {
        case .none: return "NULL"
        case let .some(value): return value.toString()
        }
    }
}


extension QueryExpression.Condition {
    
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
                throw SQLiteErrors.invalidArgument("not a array")
            }
            let arrayText = array.map{ $0.toString() }.joined(separator: ", ")
            return "\(self.key) IN (\(arrayText))"
            
        case .notIn:
            guard let array = self.value as? [StorageDataType] else {
                throw SQLiteErrors.invalidArgument("not a array")
            }
            let arrayText = array.map{ $0.toString() }.joined(separator: ", ")
            return "\(self.key) NOT IN (\(arrayText))"
        }
    }
}


extension QueryExpression.ConditionSet {
    
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


extension QueryExpression.Method.Selection {
    
    func asStatementText(for table: String) -> String {
        switch self {
        case .all:
            return "SELECT * FROM \(table)"
        case let .some(columns):
            return "SELECT \(columns.joined(separator: ", ")) FROM \(table)"
        }
    }
}

extension QueryBuilder {
    
    func asStatement() throws -> String {
        switch self.method {
        case let .select(selection):
            return try self.asSelectionQueryStatement(selection)
             
        case let .update(set):
            return try self.asUpdateStatement(set)
            
        case .delete:
            return try self.asDeleteStatement()
            
        case .none:
            throw SQLiteErrors.invalidArgument("iligal statement")
        }
    }
    
    private func asSelectionQueryStatement(_ selection: QueryExpression.Method.Selection) throws -> String {
        var sender = selection.asStatementText(for: self.tableName)
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
    
    private func asUpdateStatement(_ set: [QueryExpression.Method.ReplaceSet]) throws -> String {
        let prefix = "UPDATE \(self.tableName)"
        let setString = set
            .map{ "\($0.column) = \($0.value.asStatementText())" }
            .joined(separator: ", ")
        var sender = "\(prefix) SET \(setString)"
        if self.conditions.isEmpty == false {
            let conditionString = try self.conditions.asStatementText()
            sender = "\(sender) WHERE \(conditionString)"
        }
        return "\(sender);"
    }
    
    private func asDeleteStatement() throws -> String {
        var sender = "DELETE FROM \(self.tableName)"
        if self.conditions.isEmpty == false {
            let conditionString = try self.conditions.asStatementText()
            sender = "\(sender) WHERE \(conditionString)"
        }
        return "\(sender);"
    }
}
