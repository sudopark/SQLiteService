//
//  Query.swift
//  
//
//  Created by sudo.park on 2021/06/14.
//

import Foundation


// MARK: - QueryBuilder

public struct QueryBuilder {
    
    let tableName: TableName
    var method: QueryExpression.Method?
    var conditions: QueryExpression.ConditionSet = .empty
    var ascendings: Set<ColumnName> = []
    var descendings: Set<ColumnName> = []
    var limit: Int?
    
    init(table: TableName) {
        self.tableName = table
    }
}

// MARK: - Extensions

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
        return .and(self.capsuled(), .single(otherCondition), capsuled: false)
    }
    
    func and(_ otherConditionSet: QueryExpression.ConditionSet) -> QueryExpression.ConditionSet {
        return .and(self.capsuled(), otherConditionSet.capsuled(), capsuled: false)
    }
    
    func or(_ otherCondition: QueryExpression.Condition) -> QueryExpression.ConditionSet {
        return .or(self.capsuled(), .single(otherCondition), capsuled: false)
    }
    
    func or(_ otherConditionSet: QueryExpression.ConditionSet) -> QueryExpression.ConditionSet {
        return .or(self.capsuled(), otherConditionSet.capsuled(), capsuled: false)
    }
}


// MARK: - QueryBuilder

extension QueryBuilder {
    
    @discardableResult
    func select(_ selection: QueryExpression.Method.Selection) -> Self {
        var sender = self
        sender.method = .select(selection)
        return sender
    }
    
    @discardableResult
    func update(replace set: [QueryExpression.Method.ReplaceSet]) -> Self {
        var sender = self
        if case let .update(replaceSet) = self.method {
            sender.method = .update(replaceSet + set)
        } else {
            sender.method = .update(set)
        }
        return sender
    }
    
    @discardableResult
    public func delete() -> Self {
        var sender = self
        sender.method = .delete
        return sender
    }
}

// MARK: - QueryBuilder + Conditions builder

extension QueryBuilder {
    
    @discardableResult
    func `where`(_ condition: QueryExpression.Condition) -> Self {
        var sender = self
        if case .empty = self.conditions {
            sender.conditions = .single(condition)
        } else {
            sender.conditions  = self.conditions.and(.single(condition))
        }
        return sender
    }
    
    @discardableResult
    func `where`(_ conditions: QueryExpression.ConditionSet) -> Self {
        var sender = self
        if case .empty = self.conditions {
            sender.conditions = conditions
        } else {
            sender.conditions = self.conditions.and(conditions)
        }
        return sender
    }
    
}


// MARK: - QueryBuilder + Order and limits builder


extension QueryBuilder {
    
    @discardableResult
    func orderBy(_ column: String, isAscending: Bool) -> Self {
        var sender = self
        if isAscending {
            sender.ascendings.insert(column)
        } else {
            sender.descendings.insert(column)
        }
        return sender
    }
    
    @discardableResult
    func limit(_ count: Int) -> Self {
        var sender = self
        sender.limit = count
        return sender
    }
}
