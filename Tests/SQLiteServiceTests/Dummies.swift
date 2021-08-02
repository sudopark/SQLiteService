//
//  File 2.swift
//  
//
//  Created by sudo.park on 2021/06/19.
//

import Foundation

@testable import SQLiteService



enum Dummies { }


extension Dummies {
    
    struct Entity: RowValueType {
        
        let k1: Int
        let k2: String
        
        init(k1: Int, k2: String) {
            self.k1 = k1
            self.k2 = k2
        }
        
        init(_ cursor: CursorIterator) throws {
            self.k1 = try cursor.next().unwrap()
            self.k2 = try cursor.next().unwrap()
        }
    }
}

extension Dummies {
    
    struct Table1: Table {
        
        static var tableName: String { "Table1" }
        
        enum Column: String, TableColumn {
            case k1
            case k2
            
            var dataType: ColumnDataType {
                switch self {
                case .k1: return .integer([])
                case .k2: return .text([])
                }
            }
        }
        
        typealias EntityType = Dummies.Entity
        typealias ColumnType = Column
        
        static func scalar(_ entity: Dummies.Entity, for column: Column) -> ScalarType? {
            switch column {
            case .k1: return entity.k1
            case .k2: return entity.k2
            }
        }
    }


    struct Table2: Table {
        
        static var tableName: String { "Table2" }
        
        enum Column: String, TableColumn {
            case c1
            case c2
            
            var dataType: ColumnDataType { .integer([]) }
        }
        
        typealias ColumnType = Column
        typealias EntityType = Dummies.Entity
        
        static func scalar(_ entity: Dummies.Entity, for column: Column) -> ScalarType? {
            switch column {
            case .c1: return entity.k1
            case .c2: return entity.k2
            }
        }
    }

}


extension Dummies {
    
    
    struct TypesEntity: RowValueType {
        
        let primaryInt: Int
        let int: Int?
        let real: Double?
        let text: String?
        let bool: Bool?
        let notnull: Int
        var withDefault: String
        
        init(primaryInt: Int, int: Int?, real: Double?, text: String?,
             bool: Bool?, notnull: Int, withDefault: String) {
            self.primaryInt = primaryInt
            self.int = int
            self.real = real
            self.text = text
            self.bool = bool
            self.notnull = notnull
            self.withDefault = withDefault
        }
        
        init(_ cursor: CursorIterator) throws {
            self.primaryInt = try cursor.next().unwrap()
            self.int = cursor.next()
            self.real = cursor.next()
            self.text = cursor.next()
            self.bool = cursor.next()
            self.notnull = try cursor.next().unwrap()
            self.withDefault = try cursor.next().unwrap()
        }
    }
    
    struct TypesTable: Table {
        
        static var tableName: String { "TypesTable" }
        
        enum Column: String, TableColumn {
            
            case primaryInt = "v_p_int"
            case int = "v_int"
            case real = "v_real"
            case text = "v_text"
            case bool = "v_bool"
            case notnull = "v_notnull_int"
            case withDefault = "v_def_str"
            
            var dataType: ColumnDataType {
                switch self {
                case .primaryInt: return .integer([.primaryKey(autoIncrement: false)])
                case .int: return .integer([])
                case .real: return .real([])
                case .text: return .text([])
                case .bool: return .integer([])
                case .notnull: return .integer([.notNull])
                case .withDefault: return .text([.default("def value")])
                }
            }
        }
        
        
        typealias EntityType = TypesEntity
        typealias ColumnType = Column
        
        static func scalar(_ entity: Dummies.TypesEntity, for column: Column) -> ScalarType? {
            switch column {
            case .primaryInt: return entity.primaryInt
            case .int: return entity.int
            case .real: return entity.real
            case .text: return entity.text
            case .bool: return entity.bool
            case .notnull: return entity.notnull
            case .withDefault: return entity.withDefault
            }
        }
    }
}
