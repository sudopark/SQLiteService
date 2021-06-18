//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import Foundation


// MARK: - TableColumn -> QueryStatement.Condition

extension TableColumn {
    
    public func equal<V: StorageDataType & Equatable>(_ value: V?) -> QueryExpression.Condition {
        return .init(key: self.rawValue, operation: .equal, value: value)
    }
    
    public func notEqual<V: StorageDataType & Equatable>(_ value: V?) -> QueryExpression.Condition {
        return .init(key: self.rawValue, operation: .notEqual, value: value)
    }
    
    public func greateThan<V: StorageDataType & Comparable>(_ value: V) -> QueryExpression.Condition {
        return .init(key: self.rawValue, operation: .greaterThan(orEqual: false), value: value)
    }
    
    public func greateThanOrEqual<V: StorageDataType & Comparable>(_ value: V) -> QueryExpression.Condition {
        return .init(key: self.rawValue, operation: .greaterThan(orEqual: true), value: value)
    }
    
    public func lessThan<V: StorageDataType & Comparable>(_ value: V) -> QueryExpression.Condition {
        return .init(key: self.rawValue, operation: .lessThan(orEqual: false), value: value)
    }
    
    public func lessThanOrEqual<V: StorageDataType & Comparable>(_ value: V) -> QueryExpression.Condition {
        return .init(key: self.rawValue, operation: .lessThan(orEqual: true), value: value)
    }
    
    public func `in`<V: StorageDataType>(_ values: [V]) -> QueryExpression.Condition {
        return .init(key: self.rawValue, operation: .in, value: values)
    }
    
    public func notIn<V: StorageDataType>(_ values: [V]) -> QueryExpression.Condition {
        return .init(key: self.rawValue, operation: .notIn, value: values)
    }
}


// MARK: - TableColumn -> QueryStatement.Condition, ConditionSet operations

public func == <C: TableColumn, V: StorageDataType & Equatable>(_ column: C,
                                                                _ value: V) -> QueryExpression.Condition {
    return column.equal(value)
}

public func != <C: TableColumn, V: StorageDataType & Equatable>(_ column: C,
                                                                _ value: V) -> QueryExpression.Condition {
    return column.notEqual(value)
}

public func > <C: TableColumn, V: StorageDataType & Comparable>(_ column: C,
                                                                _ value: V) -> QueryExpression.Condition {
    return column.greateThan(value)
}

public func >= <C: TableColumn, V: StorageDataType & Comparable>(_ column: C,
                                                                 _ value: V) -> QueryExpression.Condition {
    return column.greateThanOrEqual(value)
}

public func < <C: TableColumn, V: StorageDataType & Comparable>(_ column: C,
                                                                _ value: V) -> QueryExpression.Condition {
    return column.lessThan(value)
}

public func <= <C: TableColumn, V: StorageDataType & Comparable>(_ column: C,
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


// MARK: - TableQuery

public struct SingleQuery<T: Table>: Query {
    
    var query: QueryBuilder = QueryBuilder(table: T.tableName)
}

extension SingleQuery {
    
    @discardableResult
    public func update(replace set: (T.ColumnType.Type) -> [QueryExpression.Condition]) -> Self {
        var sender = self
        let replaceSets = set(T.ColumnType.self)
            .filter{ $0.operation.isEqualOperation }
            .map{ QueryExpression.Method.ReplaceSet($0.key, $0.value) }
        sender.query = query.update(replace: replaceSets)
        return self
    }
    
    @discardableResult
    public func delete() -> Self {
        var sender = self
        sender.query = query.delete()
        return sender
    }
    
    @discardableResult
    public func `where`(_ condition: (T.ColumnType.Type) -> QueryExpression.Condition) -> Self {
        var sender = self
        sender.query = self.query.where(condition(T.ColumnType.self))
        return sender
    }
    
    @discardableResult
    public  func `where`(_ conditions: (T.ColumnType.Type) -> QueryExpression.ConditionSet) -> Self {
        var sender = self
        sender.query = self.query.where(conditions(T.ColumnType.self))
        return sender
    }
    
    @discardableResult
    public func orderBy(isAscending: Bool = false, _ column: (T.ColumnType.Type) -> T.ColumnType) -> Self {
        var sender = self
        sender.query = self.query.orderBy(column(T.ColumnType.self).rawValue, isAscending: isAscending)
        return sender
    }
    
    @discardableResult
    public func limit(_ count: Int) -> Self {
        var sender = self
        sender.query = self.query.limit(count)
        return sender
    }
}


// MARK: - Table -> Query

extension Table {
    
    public func selectAll() -> SingleQuery<Self> {
        let query = QueryBuilder(table: Self.tableName).select(.all)
        return SingleQuery(query: query)
    }
    
    public func selectSome(_ columns: (ColumnType.Type) -> [ColumnType]) -> SingleQuery<Self> {
        let query = QueryBuilder(table: Self.tableName)
            .select(.some(columns(ColumnType.self).map{ $0.rawValue }))
        return SingleQuery(query: query)
    }
    
    public func update(replace set: (ColumnType.Type) -> [QueryExpression.Condition]) -> SingleQuery<Self> {
        let replaceSets = set(ColumnType.self)
            .filter{ $0.operation.isEqualOperation }
            .map{ QueryExpression.Method.ReplaceSet($0.key, $0.value) }
        let query = QueryBuilder(table: Self.tableName)
            .update(replace: replaceSets)
        return SingleQuery(query: query)
    }
    
    public func delete() -> SingleQuery<Self> {
        let query = QueryBuilder(table: Self.tableName)
            .delete()
        return SingleQuery(query: query)
    }
}


// MARK: - get statements

extension SingleQuery {
    
    public func asStatement() throws -> String {
        return try self.query.asStatement()
    }
}

extension Table {
    
    func insertStatement(model: Model, shouldReplace: Bool) throws -> String {
        let orAnd = shouldReplace ? "REPLACE" : "IGNORE"
        let prefix = "INSERT OR \(orAnd) INTO \(Self.tableName)"
        let keyStrings = ColumnType.allCases.map{ $0.rawValue }.joined(separator: ", ")
        let valueStrings = try self.serialize(model: model)
            .map{ $0.asStatementText() }
            .joined(separator: ", ")
        return "\(prefix) (\(keyStrings)) VALUES (\(valueStrings));"
    }
    
    
}
