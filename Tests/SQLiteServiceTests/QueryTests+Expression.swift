//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import XCTest

@testable import SQLiteService

class QueryStatementTests: XCTestCase {
    
    typealias Condition = QueryExpression.Condition
    typealias ConditionSet = QueryExpression.ConditionSet
    
    private var dummyUnitConditionList: [Condition] {
        [
            .init(key: "key", operation: .equal, value: 1),
            .init(key: "key", operation: .notEqual, value: 1),
            .init(key: "key", operation: .greaterThan(orEqual: false), value: 1),
            .init(key: "key", operation: .greaterThan(orEqual: true), value: 1),
            .init(key: "key", operation: .lessThan(orEqual: false), value: 1),
            .init(key: "key", operation: .lessThan(orEqual: true), value: 1),
            .init(key: "key", operation: .in, value: [1, 2, 3]),
            .init(key: "key", operation: .notIn, value: [1, 2, 3])
        ]
    }
}


// MARK: - Test condition to conditionSet

extension QueryStatementTests {
    
    func testCondition_asSingleConditionSet() {
        // given
        
        // when
        let singels = dummyUnitConditionList.map{ $0.asSingle() }
        
        // then
        XCTAssertEqual(singels, dummyUnitConditionList.map{ ConditionSet.single($0) })
    }
    
    func testCondition_combineByAnd() {
        // given
        let condition: Condition = .init(key: "some", operation: .equal, value: 1)
        let other: Condition = .init(key: "other", operation: .greaterThan(orEqual: true), value: 1)
        
        // when
        let and = condition.and(other)
        
        // then
        XCTAssertEqual(and, ConditionSet.and(.single(condition), .single(other), capsuled: false))
    }
    
    func testCondition_combineByOr() {
        // given
        let condition: Condition = .init(key: "some", operation: .equal, value: 1)
        let other: Condition = .init(key: "other", operation: .greaterThan(orEqual: true), value: 1)
        
        // when
        let and = condition.or(other)
        
        // then
        XCTAssertEqual(and, ConditionSet.or(.single(condition), .single(other), capsuled: false))
    }
}


// MARK: - Test conditionSet combine with condition

extension QueryStatementTests {
    
    func testConditionSet_andOtherCondition() {
        // given
        let conditionSet: ConditionSet = Condition(key: "some", operation: .equal, value: 1).asSingle()
        let other: Condition = .init(key: "other", operation: .notIn, value: [1, 2, 3])
        
        // when
        let and = conditionSet.and(other)
        
        // then
        XCTAssertEqual(and, .and(conditionSet, .single(other), capsuled: false))
    }
    
    func testConditionSet_whenAndWithOtherAndOriginalIsAnd_capsuleOriginalAndCondition() {
        // given
        let originalConditions: [Condition] = [
            .init(key: "c1", operation: .equal, value: 1),
            .init(key: "c2", operation: .equal, value: 2)
        ]
        let original: ConditionSet = .and(originalConditions[0].asSingle(),
                                          originalConditions[1].asSingle(), capsuled: false)
        
        let other: Condition = .init(key: "c3", operation: .equal, value: 0)
        
        // when
        let new = original.and(other)
        
        // then
        XCTAssertEqual(new, .and(.and(originalConditions[0].asSingle(),
                                      originalConditions[1].asSingle(),
                                      capsuled: true),
                                 .single(other), capsuled: false))
    }
    
    func testConditionSet_whenAndWithOtherAndOriginalIsOr_capsuleOriginalOrCondition() {
        // given
        let originalConditions: [Condition] = [
            .init(key: "c1", operation: .equal, value: 1),
            .init(key: "c2", operation: .equal, value: 2)
        ]
        let original: ConditionSet = .or(originalConditions[0].asSingle(),
                                         originalConditions[1].asSingle(), capsuled: false)
        
        let other: Condition = .init(key: "c3", operation: .equal, value: 0)
        
        // when
        let new = original.and(other)
        
        // then
        XCTAssertEqual(new, .and(.or(originalConditions[0].asSingle(),
                                     originalConditions[1].asSingle(),
                                     capsuled: true),
                                 .single(other), capsuled: false))
    }
    
    func testConditionSet_orOtherCondition() {
        // given
        let conditionSet: ConditionSet = Condition(key: "some", operation: .equal, value: 1).asSingle()
        let other: Condition = .init(key: "other", operation: .notIn, value: [1, 2, 3])
        
        // when
        let or = conditionSet.or(other)
        
        // then
        XCTAssertEqual(or, .or(conditionSet, .single(other), capsuled: false))
    }
    
    func testConditionSet_whenORWithOtherAndOriginalIsOr_capsuleOriginalOrCondition() {
        // given
        let originalConditions: [Condition] = [
            .init(key: "c1", operation: .equal, value: 1),
            .init(key: "c2", operation: .equal, value: 2)
        ]
        let original: ConditionSet = .or(originalConditions[0].asSingle(),
                                         originalConditions[1].asSingle(), capsuled: false)
        
        let other: Condition = .init(key: "c3", operation: .equal, value: 0)
        
        // when
        let new = original.or(other)
        
        // then
        XCTAssertEqual(new, .or(.or(originalConditions[0].asSingle(),
                                    originalConditions[1].asSingle(),
                                    capsuled: true),
                                 .single(other), capsuled: false))
    }
    
    func testConditionSet_whenOrWithOtherAndOriginalIsAnd_capsuleOriginalAndCondition() {
        // given
        let originalConditions: [Condition] = [
            .init(key: "c1", operation: .equal, value: 1),
            .init(key: "c2", operation: .equal, value: 2)
        ]
        let original: ConditionSet = .and(originalConditions[0].asSingle(),
                                          originalConditions[1].asSingle(), capsuled: false)
        
        let other: Condition = .init(key: "c3", operation: .equal, value: 0)
        
        // when
        let new = original.or(other)
        
        // then
        XCTAssertEqual(new, .or(.and(originalConditions[0].asSingle(),
                                     originalConditions[1].asSingle(),
                                     capsuled: true),
                                 .single(other), capsuled: false))
    }
}

// MARK: - Test conditionSet combine with condition

extension QueryStatementTests {
    
    func testConditionSet_andWithOtherConditionSet() {
        // given
        let condition: Condition = .init(key: "c1", operation: .equal, value: 0)
        let other: Condition = .init(key: "c2", operation: .equal, value: 0)
        
        // when
        let new = condition.asSingle().and(other.asSingle())
        
        // then
        XCTAssertEqual(new, .and(.single(condition), .single(other), capsuled: false))
    }
    
    func testConditionSet_orWithOtherConditionSet() {
        // given
        let condition: Condition = .init(key: "c1", operation: .equal, value: 0)
        let other: Condition = .init(key: "c2", operation: .equal, value: 0)
        
        // when
        let new = condition.asSingle().or(other.asSingle())
        
        // then
        XCTAssertEqual(new, .or(.single(condition), .single(other), capsuled: false))
    }
}


// MARK: - Test conditions to String

extension QueryStatementTests {
    
    func testCondition_toString() {
        // given
        
        // when
        let texts = self.dummyUnitConditionList.compactMap{ try? $0.asStatementText() }
        
        // then
        XCTAssertEqual(texts, [
            "key = 1",
            "key != 1",
            "key > 1",
            "key >= 1",
            "key < 1",
            "key <= 1",
            "key IN (1, 2, 3)",
            "key NOT IN (1, 2, 3)"
        ])
    }
    
    func testCondition_isNull() {
        // given
        let conditions: [QueryExpression.Condition] = [
            .init(key: "k", operation: .equal, value: "some"),
            .init(key: "k", operation: .equal, value: nil),
            .init(key: "k", operation: .isNull, value: nil),
        ]
        
        // when
        let texts = conditions.compactMap{ try? $0.asStatementText() }
        
        // then
        XCTAssertEqual(texts, [
            "k = \'some\'",
            "k IS NULL",
            "k IS NULL",
        ])
    }
    
    func testCondition_whenInOperatorWithNotArray_error() {
        // given
        let inCondition: Condition = .init(key: "some", operation: .in, value: 1)
        let notInCondition: Condition = .init(key: "some", operation: .notIn, value: 1)
        
        // when
        // then
        XCTAssertThrowsError(try inCondition.asStatementText())
        XCTAssertThrowsError(try notInCondition.asStatementText())
    }
    
    func testConditionSet_EmptytoString() {
        // given
        let conditoionSet: ConditionSet = .empty
        
        // when
        let text = try? conditoionSet.asStatementText()
        
        // then
        XCTAssertEqual(text, "")
    }
    
    func testConditionSet_SingleToString() {
        // given
        let condition: Condition = .init(key: "some", operation: .equal, value: 10)
        let conditoionSet: ConditionSet = .single(condition)
        
        // when
        let text = try? conditoionSet.asStatementText()
        
        // then
        XCTAssertEqual(text, try? condition.asStatementText())
    }
    
    func testConditionSet_AndToString() {
        // given
        let condition: Condition = .init(key: "some", operation: .equal, value: 10)
        let conditoionSet1: ConditionSet = .and(condition.asSingle(), condition.asSingle(), capsuled: true)
        let conditoionSet2: ConditionSet = .and(condition.asSingle(), condition.asSingle(), capsuled: false)
        
        // when
        let text1 = try? conditoionSet1.asStatementText()
        let text2 = try? conditoionSet2.asStatementText()
        
        // then
        XCTAssertEqual(text1, "(some = 10 AND some = 10)")
        XCTAssertEqual(text2, "some = 10 AND some = 10")
    }
    
    func testConditionSet_OrToString() {
        // given
        let condition: Condition = .init(key: "some", operation: .equal, value: 10)
        let conditoionSet1: ConditionSet = .or(condition.asSingle(), condition.asSingle(), capsuled: true)
        let conditoionSet2: ConditionSet = .or(condition.asSingle(), condition.asSingle(), capsuled: false)
        
        // when
        let text1 = try? conditoionSet1.asStatementText()
        let text2 = try? conditoionSet2.asStatementText()
        
        // then
        XCTAssertEqual(text1, "(some = 10 OR some = 10)")
        XCTAssertEqual(text2, "some = 10 OR some = 10")
    }
    
    func testConditionSet_nestedConditionstoString() {
        // given
        let unit: Condition = .init(key: "k", operation: .equal, value: 1)
        let set1: ConditionSet = .and(unit.asSingle(), unit.asSingle(), capsuled: false)
        let set2: ConditionSet = .or(unit.asSingle(), unit.asSingle(), capsuled: false)
        
        // when
        let nested = set1.or(set2)
        let text = try? nested.asStatementText()
        
        // then
        XCTAssertEqual(text, "(k = 1 AND k = 1) OR (k = 1 OR k = 1)")
    }
}


extension QueryExpression.Condition.Operator: Equatable {
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.equal, .equal),
             (.notEqual, .notEqual),
             (.in, .in),
             (.notIn, .notIn): return true
        
        case let (.greaterThan(eq1), .greaterThan(eq2)): return eq1 == eq2
        case let (.lessThan(eq1), .lessThan(eq2)): return eq1 == eq2
            
        default: return false
        }
    }
}


extension QueryExpression.Condition: Equatable {
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.key == rhs.key
            && lhs.operation == rhs.operation
            && type(of: lhs.value) == type(of: rhs.value)
            && "\(String(describing: lhs.value))" == "\(String(describing: rhs.value))"
    }
}

extension QueryExpression.ConditionSet: Equatable {
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs){
        
        case (.empty, .empty): return true
        
        case let (.single(c1), .single(c2)): return c1 == c2
            
        case let (.and(l1, r1, c1), .and(l2, r2, c2)):
            return l1 == l2 && r1 == r2 && c1 == c2
            
        case let (.or(l1, r1, c1), .or(l2, r2, c2)):
            return l1 == l2 && r1 == r2 && c1 == c2
            
        default: return false
        }
    }
}
