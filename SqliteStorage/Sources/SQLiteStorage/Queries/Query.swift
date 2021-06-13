//
//  Query.swift
//  
//
//  Created by sudo.park on 2021/06/14.
//

import Foundation


// MARK: - Query

public struct Query {
    
    public indirect enum Selection {
        
        case all(from: TableName)
        case some(_ keys: [ColumnName], from: TableName)
        case someAt(_ pairs: [Selection], from: TableName)
    }
    
    public typealias ReplaceSet = (column: ColumnName, value: StorageDataType?)
    
    public enum QueryType {
        case select(Selection)
        case update(TableName, [ReplaceSet])
        case delete(TableName)
    }
    
    let queryType: QueryType
    let conditions: QueryStatement.ConditionSet
    let ascendings: Set<ColumnName>
    let descendings: Set<ColumnName>
    let limit: Int?
}


public class QueryBuilder {
    
    private let queryType: Query.QueryType
    
    private var conditions: QueryStatement.ConditionSet = .empty
    private var ascendings: Set<ColumnName> = []
    private var descendings: Set<ColumnName> = []
    private var limit: Int?
    
    public init(_ type: Query.QueryType) {
        self.queryType = type
    }
}


// MARK: - QueryBuilder

extension QueryBuilder {
    
    @discardableResult
    public func `where`(_ condition: QueryStatement.Condition) -> QueryBuilder {
        if case .empty = self.conditions {
            self.conditions = .single(condition)
        } else {
            self.conditions  = self.conditions.and(.single(condition))
        }
        return self
    }
    
    @discardableResult
    public func `where`(_ conditions: QueryStatement.ConditionSet) -> QueryBuilder {
        if case .empty = self.conditions {
            self.conditions = conditions
        } else {
            self.conditions = self.conditions.and(conditions)
        }
        return self
    }
    
    @discardableResult
    public func orderBy(_ column: String, isAscending: Bool) -> QueryBuilder {
        if isAscending {
            self.ascendings.insert(column)
        } else {
            self.descendings.insert(column)
        }
        return self
    }
    
    @discardableResult
    public func orderByRowID(isAscending: Bool) -> QueryBuilder {
        if isAscending {
            self.ascendings.insert("rowid")
        } else {
            self.descendings.insert("rowid")
        }
        return self
    }
    
    @discardableResult
    public func limit(_ count: Int) -> QueryBuilder {
        self.limit = count
        return self
    }
    
    public func build() -> Query {
        return .init(queryType: self.queryType,
                     conditions: self.conditions,
                     ascendings: self.ascendings,
                     descendings: self.descendings,
                     limit: self.limit)
    }
}
