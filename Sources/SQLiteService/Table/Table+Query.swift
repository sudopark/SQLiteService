//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import Foundation


// MARK: - TableColumn -> QueryStatement.Condition

extension TableColumn {
    
    public func isNull() -> QueryExpression.Condition {
        return .init(key: self.rawValue, operation: .isNull, value: nil)
    }
    
    public func equal<V: ScalarType & Equatable>(_ value: V?) -> QueryExpression.Condition {
        return .init(key: self.rawValue, operation: .equal, value: value)
    }
    
    public func notEqual<V: ScalarType & Equatable>(_ value: V?) -> QueryExpression.Condition {
        return .init(key: self.rawValue, operation: .notEqual, value: value)
    }
    
    public func greateThan<V: ScalarType & Comparable>(_ value: V) -> QueryExpression.Condition {
        return .init(key: self.rawValue, operation: .greaterThan(orEqual: false), value: value)
    }
    
    public func greateThanOrEqual<V: ScalarType & Comparable>(_ value: V) -> QueryExpression.Condition {
        return .init(key: self.rawValue, operation: .greaterThan(orEqual: true), value: value)
    }
    
    public func lessThan<V: ScalarType & Comparable>(_ value: V) -> QueryExpression.Condition {
        return .init(key: self.rawValue, operation: .lessThan(orEqual: false), value: value)
    }
    
    public func lessThanOrEqual<V: ScalarType & Comparable>(_ value: V) -> QueryExpression.Condition {
        return .init(key: self.rawValue, operation: .lessThan(orEqual: true), value: value)
    }
    
    public func `in`<V: ScalarType>(_ values: [V]) -> QueryExpression.Condition {
        return .init(key: self.rawValue, operation: .in, value: values)
    }
    
    public func notIn<V: ScalarType>(_ values: [V]) -> QueryExpression.Condition {
        return .init(key: self.rawValue, operation: .notIn, value: values)
    }
    
    public func like(_ value: String) -> QueryExpression.Condition {
        return .init(key: self.rawValue, operation: .like, value: value)
    }
}


// MARK: - TableColumn -> QueryStatement.Condition, ConditionSet operations

public func == <C: TableColumn, V: ScalarType & Equatable>(_ column: C,
                                                           _ value: V?) -> QueryExpression.Condition {
    return column.equal(value)
}

public func != <C: TableColumn, V: ScalarType & Equatable>(_ column: C,
                                                           _ value: V?) -> QueryExpression.Condition {
    return column.notEqual(value)
}

public func > <C: TableColumn, V: ScalarType & Comparable>(_ column: C,
                                                           _ value: V) -> QueryExpression.Condition {
    return column.greateThan(value)
}

public func >= <C: TableColumn, V: ScalarType & Comparable>(_ column: C,
                                                            _ value: V) -> QueryExpression.Condition {
    return column.greateThanOrEqual(value)
}

public func < <C: TableColumn, V: ScalarType & Comparable>(_ column: C,
                                                           _ value: V) -> QueryExpression.Condition {
    return column.lessThan(value)
}

public func <= <C: TableColumn, V: ScalarType & Comparable>(_ column: C,
                                                            _ value: V) -> QueryExpression.Condition {
    return column.lessThanOrEqual(value)
}

public func && (_ condition1: QueryExpression.Condition,
                _ contition2: QueryExpression.Condition) -> QueryExpression.ConditionSet {
    return condition1.and(contition2)
}

public func && (_ condition: QueryExpression.Condition,
                _ contitions: QueryExpression.ConditionSet) -> QueryExpression.ConditionSet {
    return condition.asSingle().and(contitions)
}

public func && (_ conditions: QueryExpression.ConditionSet,
                _ condition: QueryExpression.Condition) -> QueryExpression.ConditionSet {
    return conditions.and(condition)
}

public func || (_ condition1: QueryExpression.Condition,
                _ condition2: QueryExpression.Condition) -> QueryExpression.ConditionSet {
    return condition1.or(condition2)
}

public func || (_ condition: QueryExpression.Condition,
                _ conditions: QueryExpression.ConditionSet) -> QueryExpression.ConditionSet {
    return condition.asSingle().or(conditions)
}

public func || (_ conditions: QueryExpression.ConditionSet,
                _ condition: QueryExpression.Condition) -> QueryExpression.ConditionSet {
    return conditions.or(condition)
}

public func || (_ conditions1: QueryExpression.ConditionSet,
                _ conditions2: QueryExpression.ConditionSet) -> QueryExpression.ConditionSet {
    return conditions1.or(conditions2)
}


// MARK: - Table -> Query

extension Table {
    
    public static func selectAll() -> SelectQuery<Self> {
        return .init(.all)
    }
    
    public static func selectAll(_ condition: (ColumnType.Type) -> QueryExpression.Condition) -> SelectQuery<Self> {
        return self.selectAll()
            .where(condition(ColumnType.self))
    }
    
    public static func selectAll(_ conditions: (ColumnType.Type) -> QueryExpression.ConditionSet) -> SelectQuery<Self> {
        return self.selectAll()
            .where(conditions(ColumnType.self))
    }
    
    public static func selectSome(_ columns: (ColumnType.Type) -> [ColumnType]) -> SelectQuery<Self> {
        let columnNames = columns(ColumnType.self).map{ $0.rawValue }
        return .init(.some(columnNames))
    }
    
    public static func selectSome(_ columns: (ColumnType.Type) -> [ColumnType],
                                  with condition: (ColumnType.Type) -> QueryExpression.Condition) -> SelectQuery<Self> {
        return self.selectSome(columns)
            .where(condition(ColumnType.self))
    }
    
    public static func selectSome(_ columns: (ColumnType.Type) -> [ColumnType],
                                  with conditios: (ColumnType.Type) -> QueryExpression.ConditionSet) -> SelectQuery<Self> {
        return self.selectSome(columns)
            .where(conditios(ColumnType.self))
    }
    
    public static func update(replace set: (ColumnType.Type) -> [QueryExpression.Condition]) -> UpdateQuery<Self> {
        let replaceSets = set(ColumnType.self)
            .filter{ $0.operation.isEqualOperation }
            .map{ QueryExpression.ReplaceSet($0.key, $0.value) }
        return .init(replaceSets)
    }
    
    public static func delete() -> DeleteQuery<Self> {
        return .init()
    }
}



// MARK: - QueryBuildable + Table

public protocol SingleTableQuery: Query {
    
    associatedtype T: Table
}

extension SingleTableQuery where Self: QueryBuilable {
    
    @discardableResult
    public  func `where`(_ conditionSelector: (T.ColumnType.Type) -> QueryExpression.Condition) -> Self {
        let conditionSet = conditionSelector(T.ColumnType.self).asSingle()
        return self.where(conditionSet)
    }
    
    @discardableResult
    public  func `where`(_ conditionsSelector: (T.ColumnType.Type) -> QueryExpression.ConditionSet) -> Self {
        let conditionSet = conditionsSelector(T.ColumnType.self)
        return self.where(conditionSet)
    }
    
    @discardableResult
    public func orderBy(isAscending: Bool = false, _ columnSelector: (T.ColumnType.Type) -> T.ColumnType) -> Self {
        let column = columnSelector(T.ColumnType.self)
        return self.orderBy(column.rawValue, isAscending: isAscending)
    }
}


// MARK: - queries conform TableQueryBuildable

extension SelectQuery: SingleTableQuery { }

extension UpdateQuery: SingleTableQuery { }

extension DeleteQuery: SingleTableQuery { }
