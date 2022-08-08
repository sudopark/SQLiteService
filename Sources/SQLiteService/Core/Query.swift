//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/18.
//

import Foundation


public protocol Query: Sendable {
    
    @discardableResult
    func `where`(_ conditions: QueryExpression.Condition) -> Self
    
    @discardableResult
    func `where`(_ conditions: QueryExpression.ConditionSet) -> Self
    
    @discardableResult
    func orderBy(_ column: String, isAscending: Bool) -> Self
    
    @discardableResult
    func limit(_ count: Int) -> Self
    
    func asStatement() throws -> String
}


extension Query {
    
    @discardableResult
    public func `where`(_ condition: QueryExpression.Condition) -> Self {
        return self.where(condition.asSingle())
    }
    
    @discardableResult
    public func `where`(_ conditions: QueryExpression.ConditionSet) -> Self { self }
    
    @discardableResult
    public func orderBy(_ column: String, isAscending: Bool) -> Self { self }
    
    @discardableResult
    public func limit(_ count: Int) -> Self { self }
}
