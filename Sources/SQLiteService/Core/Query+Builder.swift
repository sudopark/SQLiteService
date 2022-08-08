//
//  QueryBuilder.swift
//  
//
//  Created by sudo.park on 2021/06/14.
//

import Foundation


// MARK: - QueryBuilder

public struct QueryBuilder: @unchecked Sendable {
    
    var conditions: QueryExpression.ConditionSet = .empty
    var ascendings: [ColumnName] = []
    var descendings: [ColumnName] = []
    var limit: Int?
}

// MARK: - QueryBuilder + Conditions builder

extension QueryBuilder {
    
    @discardableResult
    public func `where`(_ condition: QueryExpression.Condition) -> Self {
        var sender = self
        if case .empty = self.conditions {
            sender.conditions = .single(condition)
        } else {
            sender.conditions  = self.conditions.and(.single(condition))
        }
        return sender
    }
    
    @discardableResult
    public func `where`(_ conditions: QueryExpression.ConditionSet) -> Self {
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
    public func orderBy(_ column: String, isAscending: Bool) -> Self {
        var sender = self
        if isAscending {
            sender.ascendings.append(column)
        } else {
            sender.descendings.append(column)
        }
        return sender
    }
    
    @discardableResult
    public func limit(_ count: Int) -> Self {
        var sender = self
        sender.limit = count
        return sender
    }
}


// MARK: - QueryBuilable

public protocol QueryBuilable: Sendable {
    
    var builder: QueryBuilder { get set }
}


extension QueryBuilable where Self: Query {
    
    @discardableResult
    public func `where`(_ conditions: QueryExpression.ConditionSet) -> Self {
        var sender = self
        sender.builder = sender.builder.where(conditions)
        return sender
    }
    
    @discardableResult
    public func orderBy(_ column: String, isAscending: Bool) -> Self {
        var sender = self
        sender.builder = sender.builder.orderBy(column, isAscending: isAscending)
        return sender
    }
    
    @discardableResult
    public func limit(_ count: Int) -> Self {
        var sender = self
        sender.builder =  sender.builder.limit(count)
        return sender
    }
}


// MARK: - QueryBuilder as Statement

extension QueryBuilder {
    
    func appendConditionText(_ stmt: String) throws -> String {
        let condition = try self.conditions.asStatementText()
        guard condition.isEmpty == false else {
            return stmt
        }
        return "\(stmt) WHERE \(condition)"
    }
    
    func appendOrderText(_ stmt: String) -> String {
        let ascString = ascendings.map{ "\($0) ASC" }.joined(separator: ", ")
        let descString = descendings.map{ "\($0) DESC" }.joined(separator: ", ")
        
        let orderString = ascString.isEmpty ? descString : descString.isEmpty
            ? ascString : "\(ascString), \(descString)"
        guard orderString.isEmpty == false else {
            return stmt
        }
        return "\(stmt) ORDER BY \(orderString)"
    }
    
    func appendLimitText(_ stmt: String) -> String {
        guard let limit = self.limit else {
            return stmt
        }
        return "\(stmt) LIMIT \(limit)"
    }
}
