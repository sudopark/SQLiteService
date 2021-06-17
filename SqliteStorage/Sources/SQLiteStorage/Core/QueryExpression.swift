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
    
    enum Method {
        
        indirect enum Selection {
            case all
            case some(_ columns: [ColumnName])
        }
        
        typealias ReplaceSet = (column: ColumnName, value: StorageDataType?)
        
        case select(Selection)
        case update([ReplaceSet])
        case delete
    }
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
