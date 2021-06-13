//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import Foundation


// MARK: - TableColumn -> QueryStatement.Condition

extension TableColumn {
    
    public func equal<V: StorageDataType & Equatable>(_ value: V?) -> QueryStatement.Condition {
        return .init(key: self.rawValue, operation: .equal, value: value)
    }
    
    public func notEqual<V: StorageDataType & Equatable>(_ value: V?) -> QueryStatement.Condition {
        return .init(key: self.rawValue, operation: .notEqual, value: value)
    }
    
    public func greateThan<V: StorageDataType & Comparable>(_ value: V) -> QueryStatement.Condition {
        return .init(key: self.rawValue, operation: .greaterThan(orEqual: false), value: value)
    }
    
    public func greateThanOrEqual<V: StorageDataType & Comparable>(_ value: V) -> QueryStatement.Condition {
        return .init(key: self.rawValue, operation: .greaterThan(orEqual: true), value: value)
    }
    
    public func lessThan<V: StorageDataType & Comparable>(_ value: V) -> QueryStatement.Condition {
        return .init(key: self.rawValue, operation: .lessThan(orEqual: false), value: value)
    }
    
    public func lessThanOrEqual<V: StorageDataType & Comparable>(_ value: V) -> QueryStatement.Condition {
        return .init(key: self.rawValue, operation: .lessThan(orEqual: true), value: value)
    }
    
    public func `in`<V: StorageDataType>(_ values: [V]) -> QueryStatement.Condition {
        return .init(key: self.rawValue, operation: .in, value: values)
    }
    
    public func notIn<V: StorageDataType>(_ values: [V]) -> QueryStatement.Condition {
        return .init(key: self.rawValue, operation: .notIn, value: values)
    }
}


// MARK: - TableColumn -> QueryStatement.Condition, ConditionSet operations

public func == <C: TableColumn, V: StorageDataType & Equatable>(_ column: C,
                                                                _ value: V) -> QueryStatement.Condition {
    return column.equal(value)
}

public func != <C: TableColumn, V: StorageDataType & Equatable>(_ column: C,
                                                                _ value: V) -> QueryStatement.Condition {
    return column.notEqual(value)
}

public func > <C: TableColumn, V: StorageDataType & Comparable>(_ column: C,
                                                                _ value: V) -> QueryStatement.Condition {
    return column.greateThan(value)
}

public func >= <C: TableColumn, V: StorageDataType & Comparable>(_ column: C,
                                                                 _ value: V) -> QueryStatement.Condition {
    return column.greateThanOrEqual(value)
}

public func < <C: TableColumn, V: StorageDataType & Comparable>(_ column: C,
                                                                _ value: V) -> QueryStatement.Condition {
    return column.lessThan(value)
}

public func <= <C: TableColumn, V: StorageDataType & Comparable>(_ column: C,
                                                                 _ value: V) -> QueryStatement.Condition {
    return column.lessThanOrEqual(value)
}

public func && (_ condition1: QueryStatement.Condition,
                _ contition2: QueryStatement.Condition) -> QueryStatement.ConditionSet {
    return condition1.and(contition2)
}

public func && (_ condition: QueryStatement.Condition,
                _ contitions: QueryStatement.ConditionSet) -> QueryStatement.ConditionSet {
    return condition.asSingle().and(contitions)
}

public func && (_ conditions: QueryStatement.ConditionSet,
                _ condition: QueryStatement.Condition) -> QueryStatement.ConditionSet {
    return conditions.and(condition)
}

public func || (_ condition1: QueryStatement.Condition,
                _ condition2: QueryStatement.Condition) -> QueryStatement.ConditionSet {
    return condition1.or(condition2)
}

public func || (_ condition: QueryStatement.Condition,
                _ conditions: QueryStatement.ConditionSet) -> QueryStatement.ConditionSet {
    return condition.asSingle().or(conditions)
}

public func || (_ conditions: QueryStatement.ConditionSet,
                _ condition: QueryStatement.Condition) -> QueryStatement.ConditionSet {
    return conditions.or(condition)
}

public func || (_ conditions1: QueryStatement.ConditionSet,
                _ conditions2: QueryStatement.ConditionSet) -> QueryStatement.ConditionSet {
    return conditions1.or(conditions2)
}



// MARK: - Table -> Select Query

extension Table {
    
    public func selectAll() -> Query {
        return self.select(.all(from: Self.tableName), with: .empty)
    }
    
    public func selectAll(_ condition: (ColumnType.Type) -> QueryStatement.Condition) -> Query {
        
        return self.select(.all(from: Self.tableName),
                           with: condition(ColumnType.self).asSingle())
    }
    
    public func selectAll(_ conditions: (ColumnType.Type) -> QueryStatement.ConditionSet) -> Query {
        
        return self.select(.all(from: Self.tableName),
                           with: conditions(ColumnType.self))
    }
    
    public func select(some columns: [ColumnName]) -> Query {
        return self.select(.some(columns, from: Self.tableName), with: .empty)
    }
    
    public func select(some columns: [ColumnName],
                       _ condition: (ColumnType.Type) -> QueryStatement.Condition) -> Query {
        
        return self.select(.some(columns, from: Self.tableName),
                           with: condition(ColumnType.self).asSingle())
    }
    
    public func select(some columns: [ColumnName],
                       _ conditions: (ColumnType.Type) -> QueryStatement.ConditionSet) -> Query {
        
        return self.select(.some(columns, from: Self.tableName),
                           with: conditions(ColumnType.self))
    }
    
    private func select(_ selection: Query.Selection,
                        with conditions: QueryStatement.ConditionSet) -> Query {
        return QueryBuilder(.select(selection))
            .where(conditions)
            .build()
    }
    
    public func update(_ set: [Query.ReplaceSet]) -> Query {
        return QueryBuilder(.update(Self.tableName, set))
            .build()
    }
    
    public func update(_ set: [Query.ReplaceSet],
                       with condition: (ColumnType.Type) -> QueryStatement.Condition) -> Query {
        return QueryBuilder(.update(Self.tableName, set))
            .where(condition(ColumnType.self))
            .build()
    }
    
    public func update(_ set: [Query.ReplaceSet],
                       with conditions: (ColumnType.Type) -> QueryStatement.ConditionSet) -> Query {
        return QueryBuilder(.update(Self.tableName, set))
            .where(conditions(ColumnType.self))
            .build()
    }
    
    public func delete() -> Query {
        return QueryBuilder(.delete(Self.tableName))
            .build()
    }
    
    public func delete(_ condition: (ColumnType.Type) -> QueryStatement.Condition) -> Query {
        return QueryBuilder(.delete(Self.tableName))
            .where(condition(ColumnType.self))
            .build()
    }
    
    public func delete(_ conditions: (ColumnType.Type) -> QueryStatement.ConditionSet) -> Query {
        return QueryBuilder(.delete(Self.tableName))
            .where(conditions(ColumnType.self))
            .build()
    }
}

// MARK: - get statements

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
