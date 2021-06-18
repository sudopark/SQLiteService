//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/18.
//

import Foundation


// MARK: - JoinExpression

enum JoinExpression {
    
    enum Method: String {
        case inner = "INNER"
        case outer = "LEFT OUTER"
        case cross = "CROSS"
    }
    
    struct Selection {
        let table: TableName
        let selection: QueryExpression.Method.Selection
    }
    
    struct On {

        let method: Method
        let table: TableName
        let match: (left: ColumnName, right: ColumnName)
    }
    
    struct ColumnInTable: Hashable {
        let table: TableName
        let column: ColumnName
    }
}


// MARK: - JoinQuery

public struct JoinQuery<T: Table> {
    
    var selections: [JoinExpression.Selection]
    var joinOns: [JoinExpression.On]
    var conditionSet: QueryExpression.ConditionSet = .empty
    var ascendings: [JoinExpression.ColumnInTable] = []
    var descendings: [JoinExpression.ColumnInTable] = []
    var limit: Int?
    
    static var empty: JoinQuery<T> {
        return .init(selections: [], joinOns: [])
    }
}


// MARK: - SingleQuery + SingleQuery -> JoinQuery


public typealias JoinConditionSelector<Left: Table, Right: Table> = (Left.ColumnType.Type, Right.ColumnType.Type) -> (Left.ColumnType, Right.ColumnType)

extension SingleQuery {
    
    public func innerJoin<R: Table>(with other: SingleQuery<R>,
                                    on selector: JoinConditionSelector<T, R>,
                                    intersectCondition: Bool = true) -> JoinQuery<T> {
        
        return joinQuery(by: .inner, with: other, on: selector, intersectCondition: intersectCondition)
    }
    
    public func outerJoin<R: Table>(with other: SingleQuery<R>,
                                    on selector: JoinConditionSelector<T, R>,
                                    intersectCondition: Bool = true) -> JoinQuery<T> {
        return joinQuery(by: .outer, with: other, on: selector, intersectCondition: intersectCondition)
    }
    
    public func crossJoin<R: Table>(with other: SingleQuery<R>,
                                    on selector: JoinConditionSelector<T, R>,
                                    intersectCondition: Bool = true) -> JoinQuery<T> {
        return joinQuery(by: .cross, with: other, on: selector, intersectCondition: intersectCondition)
    }
    
    private func joinQuery<R: Table>(by method: JoinExpression.Method,
                                     with other: SingleQuery<R>,
                                     on selector: JoinConditionSelector<T, R>,
                                     intersectCondition: Bool) -> JoinQuery<T> {
        
        guard let leftSelection = self.selection?.asJoinSelection(T.tableName),
              let rightSelection = other.selection?.asJoinSelection(R.tableName) else {
            assert(false)
            return .empty
        }
        
        let match = selector(T.ColumnType.self, R.ColumnType.self)
        let joinOn: JoinExpression.On = .init(method: method, table: R.tableName,
                                              match: (left: match.0.rawValue, right: match.1.rawValue))
        
        let leftConditionSet = self.query.conditions.start(with: T.tableName)
        let rightConditionSet = other.query.conditions.start(with: R.tableName)
        let conditionSet = intersectCondition
            ? leftConditionSet.and(rightConditionSet)
            : leftConditionSet.or(rightConditionSet)
        
        let ascendings = self.query.ascendings.asJoinOrder(T.tableName)
            + other.query.ascendings.asJoinOrder(R.tableName)
        let descendings = self.query.descendings.asJoinOrder(T.tableName)
            + other.query.descendings.asJoinOrder(R.tableName)
        
        let limit = [self.query.limit, other.query.limit].compactMap{ $0 }.min()
        
        return JoinQuery<T>(selections: [leftSelection, rightSelection],
                            joinOns: [joinOn],
                            conditionSet: conditionSet,
                            ascendings: ascendings, descendings: descendings,
                            limit: limit)
    }
}



extension JoinQuery {
    
    public func innerJoin<R: Table>(with other: SingleQuery<R>,
                                    on selector: JoinConditionSelector<T, R>,
                                    intersectCondition: Bool = true) -> JoinQuery<T> {
        
        return joinQuery(by: .inner, with: other, on: selector, intersectCondition: intersectCondition)
    }
    
    public func outerJoin<R: Table>(with other: SingleQuery<R>,
                                    on selector: JoinConditionSelector<T, R>,
                                    intersectCondition: Bool = true) -> JoinQuery<T> {
        return joinQuery(by: .outer, with: other, on: selector, intersectCondition: intersectCondition)
    }
    
    public func crossJoin<R: Table>(with other: SingleQuery<R>,
                                    on selector: JoinConditionSelector<T, R>,
                                    intersectCondition: Bool = true) -> JoinQuery<T> {
        return joinQuery(by: .cross, with: other, on: selector, intersectCondition: intersectCondition)
    }
    
    private func joinQuery<R: Table>(by method: JoinExpression.Method,
                                     with other: SingleQuery<R>,
                                     on selector: JoinConditionSelector<T, R>,
                                     intersectCondition: Bool) -> JoinQuery<T> {
        
        guard let rightSelection = other.selection?.asJoinSelection(R.tableName) else {
            assert(false)
            return self
        }
        
        let match = selector(T.ColumnType.self, R.ColumnType.self)
        let newJoinOn: JoinExpression.On = .init(method: method, table: R.tableName,
                                                 match: (left: match.0.rawValue, right: match.1.rawValue))
        
        let rightConditionSet = other.query.conditions.start(with: R.tableName)
        let conditionSet = intersectCondition
            ? self.conditionSet.and(rightConditionSet)
            : self.conditionSet.or(rightConditionSet)
        
        let ascendings = self.ascendings + other.query.ascendings.asJoinOrder(R.tableName)
        let descendings = self.descendings + other.query.descendings.asJoinOrder(R.tableName)
        
        let limit = [self.limit, other.query.limit].compactMap{ $0 }.min()
        
        return JoinQuery<T>(selections: self.selections + [rightSelection],
                            joinOns: self.joinOns + [newJoinOn],
                            conditionSet: conditionSet,
                            ascendings: ascendings, descendings: descendings,
                            limit: limit)
    }
}


// MARK: - private extensions

private extension SingleQuery {
    
    var selection: QueryExpression.Method.Selection? {
        guard case let .select(selection) = self.query.method else { return nil }
        return selection
    }
}

private extension QueryExpression.Method.Selection {
    
    func asJoinSelection(_ table: TableName) -> JoinExpression.Selection {
        return .init(table: table, selection: self)
    }
}

private extension QueryExpression.Condition {
    
    func start(with table: TableName) -> Self {
        return .init(table: table, key: self.key, operation: self.operation, value: self.value)
    }
}

private extension QueryExpression.ConditionSet {
    
    func start(with table: TableName) -> Self {
        switch self {
        case .empty: return self
        case let .single(condition):
            return .single(condition.start(with: table))
            
        case let .and(left, right, capsuled):
            return .and(left.start(with: table), right.start(with: table), capsuled: capsuled)
            
        case let .or(left, right, capsuled):
            return .or(left.start(with: table), right.start(with: table), capsuled: capsuled)
        }
    }
}


private extension Array where Element == String {
    
    func asJoinOrder(_ table: TableName) -> [JoinExpression.ColumnInTable] {
        return self.map{ column -> JoinExpression.ColumnInTable in .init(table: table, column: column) }
    }
}
