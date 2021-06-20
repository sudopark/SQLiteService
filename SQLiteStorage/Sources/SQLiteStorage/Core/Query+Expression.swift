//
//  QueryExpression.swift
//  
//
//  Created by sudo.park on 2021/06/18.
//

import Foundation


typealias TableName = String
typealias ColumnName = String


// MARK: - QueryExpression

public enum QueryExpression { }


// MARK: - Methods

extension QueryExpression {
    
    enum Selection {
        case all
        case some(_ columns: [ColumnName])
    }
    
    typealias ReplaceSet = (column: ColumnName, value: ScalarType?)
}


// MARK: - Condition & ConditionSet

extension QueryExpression {
    
    public struct Condition {
        
        enum Operator {
            case equal
            case notEqual
            case greaterThan(orEqual: Bool)
            case lessThan(orEqual: Bool)
            case `in`
            case notIn
            
            var isEqualOperation: Bool {
                guard case .equal = self else { return false }
                return true
            }
        }
        
        var table: TableName?
        let key: String
        let operation: Operator
        let value: ScalarType?
    }
    
    public indirect enum ConditionSet {
        case empty
        case single(_ condition: Condition)
        case and(_ left: ConditionSet, _ right: ConditionSet, capsuled: Bool)
        case or(_ left: ConditionSet, _ right: ConditionSet, capsuled: Bool)
        
        func capsuled() -> ConditionSet {
            switch self {
            case let.and(left, right, _):
                return .and(left, right, capsuled: true)
            case let .or(left, right, _):
                return .or(left, right, capsuled: true)
            default:
                return self
            }
        }
        
        var isEmpty: Bool {
            guard case .empty = self else { return false }
            return true
        }
    }
}


// MARK: - Extensions for combine

extension QueryExpression.Condition {
    
    func asSingle() -> QueryExpression.ConditionSet {
        return .single(self)
    }
    
    func and(_ other: QueryExpression.Condition) -> QueryExpression.ConditionSet {
        return .and(.single(self), .single(other), capsuled: false)
    }
    
    func or(_ other: QueryExpression.Condition) -> QueryExpression.ConditionSet {
        return .or(.single(self), .single(other), capsuled: false)
    }
}

extension QueryExpression.ConditionSet {
    
    func and(_ otherCondition: QueryExpression.Condition) -> QueryExpression.ConditionSet {
        switch self {
        case .empty: return otherCondition.asSingle()
        case .single:
            return .and(self, .single(otherCondition), capsuled: false)
            
        default:
            return .and(self.capsuled(), .single(otherCondition), capsuled: false)
        }
    }
    
    func and(_ otherConditionSet: QueryExpression.ConditionSet) -> QueryExpression.ConditionSet {
        switch (self, otherConditionSet) {
        case (.empty, .empty): return .empty
        case (.empty, _): return otherConditionSet
        case (_, .empty): return self
        default:
            return .and(self.capsuled(), otherConditionSet.capsuled(), capsuled: false)
        }
    }
    
    func or(_ otherCondition: QueryExpression.Condition) -> QueryExpression.ConditionSet {
        switch self {
        case .empty: return otherCondition.asSingle()
        case .single:
            return .or(self, .single(otherCondition), capsuled: false)
            
        default:
            return .or(self.capsuled(), .single(otherCondition), capsuled: false)
        }
    }
    
    func or(_ otherConditionSet: QueryExpression.ConditionSet) -> QueryExpression.ConditionSet {
        switch (self, otherConditionSet) {
        case (.empty, .empty): return .empty
        case (.empty, _): return otherConditionSet
        case (_, .empty): return self
        default:
            return .or(self.capsuled(), otherConditionSet.capsuled(), capsuled: false)
        }
    }
}


// MARK: - QueryExpression as Statement

extension ScalarType {
    
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


extension Optional where Wrapped == ScalarType {
    
    func asStatementText() -> String {
        switch self {
        case .none: return "NULL"
        case let .some(value): return value.toString()
        }
    }
}

extension QueryExpression.Condition {
    
    private var column: String {
        guard let table = self.table else { return self.key }
        return "\(table).\(self.key)"
    }
    
    func asStatementText() throws -> String {
        switch self.operation {
        case .equal:
            return "\(self.column) = \(self.value.asStatementText())"
            
        case .notEqual:
            return "\(self.column) != \(self.value.asStatementText())"
            
        case let .greaterThan(orEqual):
            return "\(self.column) \(orEqual ? ">=" : ">") \(self.value.asStatementText())"
            
        case let .lessThan(orEqual):
            return "\(self.column) \(orEqual ? "<=" : "<") \(self.value.asStatementText())"
            
        case .in:
            guard let array = self.value as? [ScalarType] else {
                throw SQLiteErrors.invalidArgument("not a array")
            }
            let arrayText = array.map{ $0.toString() }.joined(separator: ", ")
            return "\(self.column) IN (\(arrayText))"
            
        case .notIn:
            guard let array = self.value as? [ScalarType] else {
                throw SQLiteErrors.invalidArgument("not a array")
            }
            let arrayText = array.map{ $0.toString() }.joined(separator: ", ")
            return "\(self.column) NOT IN (\(arrayText))"
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

