//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/18.
//

import Foundation


// MARK: - JoinExpression

enum JoinExpression: Sendable {
    
    enum Method: String, Sendable {
        case inner = "INNER"
        case outer = "LEFT OUTER"
        case cross = "CROSS"
    }
    
    struct Selection {
        let table: TableName
        let selection: QueryExpression.Selection
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

public struct JoinQuery<T: Table>: Query {
    
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

extension SelectQuery {
    
    public func innerJoin<R: Table>(with other: SelectQuery<R>,
                                    on selector: JoinConditionSelector<T, R>,
                                    intersectCondition: Bool = true) -> JoinQuery<T> {
        
        return joinQuery(by: .inner, with: other, on: selector, intersectCondition: intersectCondition)
    }
    
    public func outerJoin<R: Table>(with other: SelectQuery<R>,
                                    on selector: JoinConditionSelector<T, R>,
                                    intersectCondition: Bool = true) -> JoinQuery<T> {
        return joinQuery(by: .outer, with: other, on: selector, intersectCondition: intersectCondition)
    }
    
    public func crossJoin<R: Table>(with other: SelectQuery<R>,
                                    on selector: JoinConditionSelector<T, R>,
                                    intersectCondition: Bool = true) -> JoinQuery<T> {
        return joinQuery(by: .cross, with: other, on: selector, intersectCondition: intersectCondition)
    }
    
    private func joinQuery<R: Table>(by method: JoinExpression.Method,
                                     with other: SelectQuery<R>,
                                     on selector: JoinConditionSelector<T, R>,
                                     intersectCondition: Bool) -> JoinQuery<T> {
        
        
        let leftSelection = self.selection.asJoinSelection(T.tableName)
        let rightSelection = other.selection.asJoinSelection(R.tableName)
        
        let match = selector(T.ColumnType.self, R.ColumnType.self)
        let joinOn: JoinExpression.On = .init(method: method, table: R.tableName,
                                              match: (left: match.0.rawValue, right: match.1.rawValue))
        
        let leftConditionSet = self.builder.conditions.start(with: T.tableName)
        let rightConditionSet = other.builder.conditions.start(with: R.tableName)
        let conditionSet = intersectCondition
            ? leftConditionSet.and(rightConditionSet)
            : leftConditionSet.or(rightConditionSet)
        
        let ascendings = self.builder.ascendings.asJoinOrder(T.tableName)
            + other.builder.ascendings.asJoinOrder(R.tableName)
        let descendings = self.builder.descendings.asJoinOrder(T.tableName)
            + other.builder.descendings.asJoinOrder(R.tableName)
        
        let limit = [self.builder.limit, other.builder.limit].compactMap{ $0 }.min()
        
        return JoinQuery<T>(selections: [leftSelection, rightSelection],
                            joinOns: [joinOn],
                            conditionSet: conditionSet,
                            ascendings: ascendings, descendings: descendings,
                            limit: limit)
    }
}



extension JoinQuery {
    
    public func innerJoin<R: Table>(with other: SelectQuery<R>,
                                    on selector: JoinConditionSelector<T, R>,
                                    intersectCondition: Bool = true) -> JoinQuery<T> {
        
        return joinQuery(by: .inner, with: other, on: selector, intersectCondition: intersectCondition)
    }
    
    public func outerJoin<R: Table>(with other: SelectQuery<R>,
                                    on selector: JoinConditionSelector<T, R>,
                                    intersectCondition: Bool = true) -> JoinQuery<T> {
        return joinQuery(by: .outer, with: other, on: selector, intersectCondition: intersectCondition)
    }
    
    public func crossJoin<R: Table>(with other: SelectQuery<R>,
                                    on selector: JoinConditionSelector<T, R>,
                                    intersectCondition: Bool = true) -> JoinQuery<T> {
        return joinQuery(by: .cross, with: other, on: selector, intersectCondition: intersectCondition)
    }
    
    private func joinQuery<R: Table>(by method: JoinExpression.Method,
                                     with other: SelectQuery<R>,
                                     on selector: JoinConditionSelector<T, R>,
                                     intersectCondition: Bool) -> JoinQuery<T> {
        
        let rightSelection = other.selection.asJoinSelection(R.tableName)
        
        let match = selector(T.ColumnType.self, R.ColumnType.self)
        let newJoinOn: JoinExpression.On = .init(method: method, table: R.tableName,
                                                 match: (left: match.0.rawValue, right: match.1.rawValue))
        
        let rightConditionSet = other.builder.conditions.start(with: R.tableName)
        let conditionSet = intersectCondition
            ? self.conditionSet.and(rightConditionSet)
            : self.conditionSet.or(rightConditionSet)
        
        let ascendings = self.ascendings + other.builder.ascendings.asJoinOrder(R.tableName)
        let descendings = self.descendings + other.builder.descendings.asJoinOrder(R.tableName)
        
        let limit = [self.limit, other.builder.limit].compactMap{ $0 }.min()
        
        return JoinQuery<T>(selections: self.selections + [rightSelection],
                            joinOns: self.joinOns + [newJoinOn],
                            conditionSet: conditionSet,
                            ascendings: ascendings, descendings: descendings,
                            limit: limit)
    }
}


// MARK: - JoinQuery as Statement

extension JoinQuery {
    
    public func asStatement() throws -> String {
        
        let selectedColumnTexts = self.selections
            .flatMap{ $0.selection.selectedColumnTexts(on: $0.table) }.joined(separator: ", ")
        
        var sender = "SELECT \(selectedColumnTexts) FROM \(T.tableName)"
        
        let onTexts = self.joinOns.map{ $0.asStatement(left: T.tableName) }.joined(separator: ", ")
        sender = "\(sender) \(onTexts)"
        
        let condition = try self.conditionSet.asStatementText()
        if condition.isEmpty == false {
            sender = "\(sender) WHERE \(condition)"
        }
        
        let ascString = ascendings.map{ "\($0.table).\($0.column) ASC" }.joined(separator: ", ")
        let descString = descendings.map{ "\($0.table).\($0.column) DESC" }.joined(separator: ", ")
        
        let orderString = ascString.isEmpty ? descString : descString.isEmpty
            ? ascString : "\(ascString), \(descString)"
        if orderString.isEmpty == false {
            sender = "\(sender) ORDER BY \(orderString)"
        }
        
        if let limit = self.limit {
            sender = "\(sender) LIMIT \(limit)"
        }
        return "\(sender);"
    }
}

private extension QueryExpression.Selection {
    
    func selectedColumnTexts(on table: TableName) -> [String] {
        switch self {
        case .all:
            return ["\(table).*"]
            
        case let .some(columns):
            return columns.map{ "\(table).\($0)"}
        }
    }
}

private extension JoinExpression.On {
    
    func asStatement(left table: TableName) -> String {
        let (left, right) = (table, self.table)
        return "\(self.method.rawValue) JOIN \(right) ON \(left).\(self.match.left) = \(right).\(match.right)"
    }
}


// MARK: - private extensions

private extension QueryExpression.Selection {
    
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
