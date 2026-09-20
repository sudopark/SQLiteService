//
//  TableMacroTests.swift
//
//
//  Created by sudo.park.
//

import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

@testable import SQLiteServiceMacrosPlugin


class TableMacroTests: XCTestCase {

    private let macros: [String: Macro.Type] = [
        "Table": TableMacro.self,
        "Column": ColumnMacro.self
    ]
}


extension TableMacroTests {

    func testMacro_expandColumnsAndEntityFollowingDeclarationOrder() {
        assertMacroExpansion(
            """
            @Table("Users")
            struct UserTable {
                @Column(.primaryKey(autoIncrement: false)) var uid: String
                @Column(.notNull) var name: String
                var age: Int?
                @Column(.unique, .notNull) var email: String
                var phone: String?
                @Column(name: "intro") var introduction: String?
            }
            """,
            expandedSource: """
            struct UserTable {
                var uid: String
                var name: String
                var age: Int?
                var email: String
                var phone: String?
                var introduction: String?

                enum Columns: String, TableColumn {
                    case uid
                    case name
                    case age
                    case email
                    case phone
                    case introduction = "intro"

                    var dataType: ColumnDataType {
                        switch self {
                        case .uid:
                            return .text([.primaryKey(autoIncrement: false)])
                        case .name:
                            return .text([.notNull])
                        case .age:
                            return .integer([])
                        case .email:
                            return .text([.unique, .notNull])
                        case .phone:
                            return .text([])
                        case .introduction:
                            return .text([])
                        }
                    }
                }

                struct Entity: RowValueType {
                    let uid: String
                    let name: String
                    var age: Int?
                    let email: String
                    var phone: String?
                    var introduction: String?

                    init(uid: String, name: String, age: Int? = nil, email: String, phone: String? = nil, introduction: String? = nil) {
                        self.uid = uid
                        self.name = name
                        self.age = age
                        self.email = email
                        self.phone = phone
                        self.introduction = introduction
                    }

                    init(_ cursor: CursorIterator) throws {
                        self.uid = try cursor.next().unwrap()
                        self.name = try cursor.next().unwrap()
                        self.age = cursor.next()
                        self.email = try cursor.next().unwrap()
                        self.phone = cursor.next()
                        self.introduction = cursor.next()
                    }
                }

                typealias ColumnType = Columns

                typealias EntityType = Entity

                static var tableName: String {
                    "Users"
                }

                static func scalar(_ entity: Entity, for column: Columns) -> ScalarType? {
                    switch column {
                    case .uid:
                        return entity.uid
                    case .name:
                        return entity.name
                    case .age:
                        return entity.age
                    case .email:
                        return entity.email
                    case .phone:
                        return entity.phone
                    case .introduction:
                        return entity.introduction
                    }
                }
            }

            extension UserTable: Table {
            }
            """,
            macros: self.macros
        )
    }
}

extension TableMacroTests {

    func testMacro_mapSwiftTypeToColumnDataType() {
        assertMacroExpansion(
            """
            @Table("Values")
            struct ValueTable {
                let int: Int
                let bool: Bool
                let double: Double
                let float: Float
            }
            """,
            expandedSource: """
            struct ValueTable {
                let int: Int
                let bool: Bool
                let double: Double
                let float: Float

                enum Columns: String, TableColumn {
                    case int
                    case bool
                    case double
                    case float

                    var dataType: ColumnDataType {
                        switch self {
                        case .int:
                            return .integer([])
                        case .bool:
                            return .integer([])
                        case .double:
                            return .real([])
                        case .float:
                            return .real([])
                        }
                    }
                }

                struct Entity: RowValueType {
                    let int: Int
                    let bool: Bool
                    let double: Double
                    let float: Float

                    init(int: Int, bool: Bool, double: Double, float: Float) {
                        self.int = int
                        self.bool = bool
                        self.double = double
                        self.float = float
                    }

                    init(_ cursor: CursorIterator) throws {
                        self.int = try cursor.next().unwrap()
                        self.bool = try cursor.next().unwrap()
                        self.double = try cursor.next().unwrap()
                        self.float = try cursor.next().unwrap()
                    }
                }

                typealias ColumnType = Columns

                typealias EntityType = Entity

                static var tableName: String {
                    "Values"
                }

                static func scalar(_ entity: Entity, for column: Columns) -> ScalarType? {
                    switch column {
                    case .int:
                        return entity.int
                    case .bool:
                        return entity.bool
                    case .double:
                        return entity.double
                    case .float:
                        return entity.float
                    }
                }
            }

            extension ValueTable: Table {
            }
            """,
            macros: self.macros
        )
    }

    func testMacro_whenTableIsPublic_generateMembersAsPublic() {
        assertMacroExpansion(
            """
            @Table("Words")
            public struct WordTable {
                @Column(.notNull) var word: String
            }
            """,
            expandedSource: """
            public struct WordTable {
                var word: String

                public enum Columns: String, TableColumn {
                    case word

                    public var dataType: ColumnDataType {
                        switch self {
                        case .word:
                            return .text([.notNull])
                        }
                    }
                }

                public struct Entity: RowValueType {
                    public let word: String

                    public init(word: String) {
                        self.word = word
                    }

                    public init(_ cursor: CursorIterator) throws {
                        self.word = try cursor.next().unwrap()
                    }
                }

                public typealias ColumnType = Columns

                public typealias EntityType = Entity

                public static var tableName: String {
                    "Words"
                }

                public static func scalar(_ entity: Entity, for column: Columns) -> ScalarType? {
                    switch column {
                    case .word:
                        return entity.word
                    }
                }
            }

            extension WordTable: Table {
            }
            """,
            macros: self.macros
        )
    }

    func testMacro_ignoreStaticProperties() {
        assertMacroExpansion(
            """
            @Table("Words")
            struct WordTable {
                var word: String
                static var prefix: String = "w"
            }
            """,
            expandedSource: """
            struct WordTable {
                var word: String
                static var prefix: String = "w"

                enum Columns: String, TableColumn {
                    case word

                    var dataType: ColumnDataType {
                        switch self {
                        case .word:
                            return .text([])
                        }
                    }
                }

                struct Entity: RowValueType {
                    let word: String

                    init(word: String) {
                        self.word = word
                    }

                    init(_ cursor: CursorIterator) throws {
                        self.word = try cursor.next().unwrap()
                    }
                }

                typealias ColumnType = Columns

                typealias EntityType = Entity

                static var tableName: String {
                    "Words"
                }

                static func scalar(_ entity: Entity, for column: Columns) -> ScalarType? {
                    switch column {
                    case .word:
                        return entity.word
                    }
                }
            }

            extension WordTable: Table {
            }
            """,
            macros: self.macros
        )
    }

    func testMacro_whenColumnIsComputed_diagnose() {
        assertMacroExpansion(
            """
            @Table("Words")
            struct WordTable {
                var word: String
                var upperCased: String {
                    self.word.uppercased()
                }
            }
            """,
            expandedSource: """
            struct WordTable {
                var word: String
                var upperCased: String {
                    self.word.uppercased()
                }
            }
            """,
            diagnostics: [
                .init(
                    message: "@Table column 'upperCased' cannot have an accessor. A table declares stored properties only, the entity is inferred from their types.",
                    line: 1, column: 1
                )
            ],
            macros: self.macros
        )
    }

    func testMacro_whenColumnHasObserver_diagnose() {
        assertMacroExpansion(
            """
            @Table("Words")
            struct WordTable {
                var word: String {
                    didSet { }
                }
            }
            """,
            expandedSource: """
            struct WordTable {
                var word: String {
                    didSet { }
                }
            }
            """,
            diagnostics: [
                .init(
                    message: "@Table column 'word' cannot have an accessor. A table declares stored properties only, the entity is inferred from their types.",
                    line: 1, column: 1
                )
            ],
            macros: self.macros
        )
    }

    func testMacro_whenColumnTypeIsNotSupported_diagnose() {
        assertMacroExpansion(
            """
            @Table("Words")
            struct WordTable {
                var word: Date
            }
            """,
            expandedSource: """
            struct WordTable {
                var word: Date
            }
            """,
            diagnostics: [
                .init(
                    message: "@Table column 'word' has unsupported type 'Date'. Int, Bool, String, Double and Float are supported.",
                    line: 1, column: 1
                )
            ],
            macros: self.macros
        )
    }

    func testMacro_whenAttachedToNotStruct_diagnose() {
        assertMacroExpansion(
            """
            @Table("Words")
            class WordTable {
                var word: String = ""
            }
            """,
            expandedSource: """
            class WordTable {
                var word: String = ""
            }
            """,
            diagnostics: [
                .init(message: "@Table can only be applied to a struct.", line: 1, column: 1)
            ],
            macros: self.macros
        )
    }
}

extension TableMacroTests {

    func testMacro_shareTypeAnnotationOfMultipleBindings() {
        assertMacroExpansion(
            """
            @Table("Words")
            struct WordTable {
                var word, spelling: String
            }
            """,
            expandedSource: """
            struct WordTable {
                var word, spelling: String

                enum Columns: String, TableColumn {
                    case word
                    case spelling

                    var dataType: ColumnDataType {
                        switch self {
                        case .word:
                            return .text([])
                        case .spelling:
                            return .text([])
                        }
                    }
                }

                struct Entity: RowValueType {
                    let word: String
                    let spelling: String

                    init(word: String, spelling: String) {
                        self.word = word
                        self.spelling = spelling
                    }

                    init(_ cursor: CursorIterator) throws {
                        self.word = try cursor.next().unwrap()
                        self.spelling = try cursor.next().unwrap()
                    }
                }

                typealias ColumnType = Columns

                typealias EntityType = Entity

                static var tableName: String {
                    "Words"
                }

                static func scalar(_ entity: Entity, for column: Columns) -> ScalarType? {
                    switch column {
                    case .word:
                        return entity.word
                    case .spelling:
                        return entity.spelling
                    }
                }
            }

            extension WordTable: Table {
            }
            """,
            macros: self.macros
        )
    }

    func testMacro_keepBacktickedPropertyNameAsIdentifier() {
        assertMacroExpansion(
            """
            @Table("Words")
            struct WordTable {
                var `default`: String
            }
            """,
            expandedSource: """
            struct WordTable {
                var `default`: String

                enum Columns: String, TableColumn {
                    case `default`

                    var dataType: ColumnDataType {
                        switch self {
                        case .`default`:
                            return .text([])
                        }
                    }
                }

                struct Entity: RowValueType {
                    let `default`: String

                    init(`default`: String) {
                        self.`default` = `default`
                    }

                    init(_ cursor: CursorIterator) throws {
                        self.`default` = try cursor.next().unwrap()
                    }
                }

                typealias ColumnType = Columns

                typealias EntityType = Entity

                static var tableName: String {
                    "Words"
                }

                static func scalar(_ entity: Entity, for column: Columns) -> ScalarType? {
                    switch column {
                    case .`default`:
                        return entity.`default`
                    }
                }
            }

            extension WordTable: Table {
            }
            """,
            macros: self.macros
        )
    }

    func testMacro_keepQuotesOfTableAndColumnNameLiteral() {
        assertMacroExpansion(
            #"""
            @Table("say\"hello")
            struct WordTable {
                @Column(name: "say\"word") var word: String
            }
            """#,
            expandedSource: #"""
            struct WordTable {
                var word: String

                enum Columns: String, TableColumn {
                    case word = "say\"word"

                    var dataType: ColumnDataType {
                        switch self {
                        case .word:
                            return .text([])
                        }
                    }
                }

                struct Entity: RowValueType {
                    let word: String

                    init(word: String) {
                        self.word = word
                    }

                    init(_ cursor: CursorIterator) throws {
                        self.word = try cursor.next().unwrap()
                    }
                }

                typealias ColumnType = Columns

                typealias EntityType = Entity

                static var tableName: String {
                    "say\"hello"
                }

                static func scalar(_ entity: Entity, for column: Columns) -> ScalarType? {
                    switch column {
                    case .word:
                        return entity.word
                    }
                }
            }

            extension WordTable: Table {
            }
            """#,
            macros: self.macros
        )
    }

    func testMacro_whenColumnNameIsNotLiteral_diagnose() {
        assertMacroExpansion(
            """
            @Table("Words")
            struct WordTable {
                @Column(name: someName) var word: String
            }
            """,
            expandedSource: """
            struct WordTable {
                var word: String
            }
            """,
            diagnostics: [
                .init(
                    message: "@Column(name:) requires a string literal, 'someName' is not one.",
                    line: 1, column: 1
                )
            ],
            macros: self.macros
        )
    }
}

extension TableMacroTests {

    func testMacro_declareOptionalEntityFieldAsMutableWithNilDefault() {
        assertMacroExpansion(
            """
            @Table("Words")
            struct WordTable {
                let word: String
                let count: Int?
            }
            """,
            expandedSource: """
            struct WordTable {
                let word: String
                let count: Int?

                enum Columns: String, TableColumn {
                    case word
                    case count

                    var dataType: ColumnDataType {
                        switch self {
                        case .word:
                            return .text([])
                        case .count:
                            return .integer([])
                        }
                    }
                }

                struct Entity: RowValueType {
                    let word: String
                    var count: Int?

                    init(word: String, count: Int? = nil) {
                        self.word = word
                        self.count = count
                    }

                    init(_ cursor: CursorIterator) throws {
                        self.word = try cursor.next().unwrap()
                        self.count = cursor.next()
                    }
                }

                typealias ColumnType = Columns

                typealias EntityType = Entity

                static var tableName: String {
                    "Words"
                }

                static func scalar(_ entity: Entity, for column: Columns) -> ScalarType? {
                    switch column {
                    case .word:
                        return entity.word
                    case .count:
                        return entity.count
                    }
                }
            }

            extension WordTable: Table {
            }
            """,
            macros: self.macros
        )
    }
}
