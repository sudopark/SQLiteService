//
//  QueryStatement.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import Foundation


public typealias TableName = String
public typealias ColumnName = String


public enum QueryStatement {
    
    public enum Operator {
        case equal
        case notEqual
        case greaterThan(orEqual: Bool)
        case lessThan(orEqual: Bool)
        case `in`
        case notIn
    }
    
    public struct Condition {
        let key: String
        let operation: Operator
        let value: StorageDataType?
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


extension QueryStatement.Condition {
    
    public func asSingle() -> QueryStatement.ConditionSet {
        return .single(self)
    }
    
    public func and(_ other: QueryStatement.Condition) -> QueryStatement.ConditionSet {
        return .and(.single(self), .single(other), capsuled: false)
    }
    
    public func or(_ other: QueryStatement.Condition) -> QueryStatement.ConditionSet {
        return .or(.single(self), .single(other), capsuled: false)
    }
}

extension QueryStatement.ConditionSet {
    
    func and(_ otherCondition: QueryStatement.Condition) -> QueryStatement.ConditionSet {
        return .and(self.capsuled(), .single(otherCondition), capsuled: false)
    }
    
    func and(_ otherConditionSet: QueryStatement.ConditionSet) -> QueryStatement.ConditionSet {
        return .and(self.capsuled(), otherConditionSet.capsuled(), capsuled: false)
    }
    
    func or(_ otherCondition: QueryStatement.Condition) -> QueryStatement.ConditionSet {
        return .or(self.capsuled(), .single(otherCondition), capsuled: false)
    }
    
    func or(_ otherConditionSet: QueryStatement.ConditionSet) -> QueryStatement.ConditionSet {
        return .or(self.capsuled(), otherConditionSet.capsuled(), capsuled: false)
    }
}
