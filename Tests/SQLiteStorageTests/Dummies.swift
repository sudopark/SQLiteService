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
    
    struct Model {
        
        let k1: Int
        let k2: String
        
        static func deserialize(_ cursor: OpaquePointer) throws -> Dummies.Model {
            let int: Int = try cursor[0].unwrap()
            let str: String = try cursor[1].unwrap()
            return .init(k1: int, k2: str)
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
        
        static func serialize(model: Dummies.Model, for column: Column) -> ScalarType? {
            switch column {
            case .k1: return model.k1
            case .k2: return model.k2
            }
        }
        
        static func deserialize(_ cursor: OpaquePointer) throws -> Dummies.Model {
            return .init(k1: try cursor[0].unwrap(),
                         k2: try cursor[1].unwrap())
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
        
        static func serialize(model: Dummies.Model, for column: Column) -> ScalarType? {
            switch column {
            case .c1: return model.k1
            case .c2: return model.k2
            }
        }
        
        static func deserialize(_ cursor: OpaquePointer) throws -> Model {
            
            return .init(k1: try cursor[0].unwrap(),
                         k2: try cursor[1].unwrap())
        }
    }

}


extension Dummies {
    
    
    struct TypesModel {
        
        let primaryInt: Int
        let int: Int?
        let real: Double?
        let text: String?
        let bool: Bool?
        let notnull: Int
        var withDefault: String
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
        
        static func serialize(model: Dummies.TypesModel, for column: Column) -> ScalarType? {
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
        
        static func deserialize(_ cursor: OpaquePointer) throws -> Dummies.TypesModel {
            
            return .init(primaryInt: try cursor[0].unwrap(),
                         int: cursor[1],
                         real: cursor[2],
                         text: cursor[3],
                         bool: cursor[4],
                         notnull: try cursor[5].unwrap(),
                         withDefault: cursor[6] ?? "default")
        }
    }
}
