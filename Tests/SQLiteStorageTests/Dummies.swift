//
//  File 2.swift
//  
//
//  Created by sudo.park on 2021/06/19.
//

import Foundation

@testable import SQLiteStorage



enum Dummies { }


extension Dummies {
    
    struct Model: RowValueType {
        
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
        
        typealias Model = Dummies.Model
        typealias ColumnType = Column
        
        static func scalar(_ model: Dummies.Model, for column: Column) -> ScalarType? {
            switch column {
            case .k1: return model.k1
            case .k2: return model.k2
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
        typealias Model = Dummies.Model
        
        static func scalar(_ model: Dummies.Model, for column: Column) -> ScalarType? {
            switch column {
            case .c1: return model.k1
            case .c2: return model.k2
            }
        }
    }

}


extension Dummies {
    
    
    struct TypesModel: RowValueType {
        
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
        
        
        typealias Model = TypesModel
        typealias ColumnType = Column
        
        static func scalar(_ model: Dummies.TypesModel, for column: Column) -> ScalarType? {
            switch column {
            case .primaryInt: return model.primaryInt
            case .int: return model.int
            case .real: return model.real
            case .text: return model.text
            case .bool: return model.bool
            case .notnull: return model.notnull
            case .withDefault: return model.withDefault
            }
        }
    }
}
