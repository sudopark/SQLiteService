//
//  SelectQueryBuilder.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import Foundation


// MARK: - SelectQueryBuilder

public class SelectQueryBuilder {
    
    private var conditionSet: QueryStatement.ConditionSet = .empty
    private var ascendings: Set<ColumnName> = []
    private var descendings: Set<ColumnName> = []
    private var limit: Int?
    
    private let selection: SelectQuery.SelectionType
    
    public init(_ selection: SelectQuery.SelectionType) {
        self.selection = selection
    }
}


extension SelectQueryBuilder {
    
    @discardableResult
    public func `where`(_ condition: QueryStatement.Condition) -> SelectQueryBuilder {
        if case .empty = self.conditionSet {
            self.conditionSet = .single(condition)
        } else {
            self.conditionSet  = self.conditionSet.and(.single(condition))
        }
        return self
    }
    
    @discardableResult
    public func `where`(_ conditions: QueryStatement.ConditionSet) -> SelectQueryBuilder {
        if case .empty = self.conditionSet {
            self.conditionSet = conditions
        } else {
            self.conditionSet = self.conditionSet.and(conditions)
        }
        return self
    }
    
    @discardableResult
    public func orderBy(_ column: String, isAscending: Bool) -> SelectQueryBuilder {
        if isAscending {
            self.ascendings.insert(column)
        } else {
            self.descendings.insert(column)
        }
        return self
    }
    
    @discardableResult
    public func orderByRowID(isAscending: Bool) -> SelectQueryBuilder {
        if isAscending {
            self.ascendings.insert("rowid")
        } else {
            self.descendings.insert("rowid")
        }
        return self
    }
    
    @discardableResult
    public func limit(_ count: Int) -> SelectQueryBuilder {
        self.limit = count
        return self
    }
    
    public func build() -> SelectQuery {
        return .init(selection: self.selection,
                     conditions: self.conditionSet,
                     ascendings: self.ascendings,
                     descendings: self.descendings,
                     limit: self.limit)
    }
}

