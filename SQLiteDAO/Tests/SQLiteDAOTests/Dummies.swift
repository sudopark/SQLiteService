//
//  File 2.swift
//  
//
//  Created by sudo.park on 2021/06/19.
//

import Foundation

@testable import SQLiteDAO



enum Dummies { }


extension Dummies {
    
    struct Model {
        
        let k1: Int
        let k2: String
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
        
        func serialize(model: Model) throws -> [StorageDataType?] {
            return [model.k1, model.k2]
        }
        
        func deserialize(cursor: OpaquePointer?) throws -> Model {
            guard let cursor = cursor else {
                throw SQLiteErrors.step("deserialize")
            }
            let int: Int = try cursor[0].unwrap()
            let str: String = try cursor[1].unwrap()
            return .init(k1: int, k2: str)
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
        
        func serialize(model: Model) throws -> [StorageDataType?] {
            return [model.k1, model.k2]
        }
        
        func deserialize(cursor: OpaquePointer?) throws -> Model {
            guard let cursor = cursor else {
                throw SQLiteErrors.step("deserialize")
            }
            let int: Int = try cursor[0].unwrap()
            let str: String = try cursor[1].unwrap()
            return .init(k1: int, k2: str)
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
        
        func serialize(model: Dummies.TypesModel) throws -> [StorageDataType?] {
            return [
                model.primaryInt,
                model.int,
                model.real,
                model.text,
                model.bool,
                model.notnull,
                model.withDefault
            ]
        }
        
        func deserialize(cursor: OpaquePointer?) throws -> Dummies.TypesModel {
            guard let cursor = cursor else {
                throw SQLiteErrors.step("deserialize")
            }
            let primary: Int = try cursor[0].unwrap()
            let int: Int? = cursor[1]
            let real: Double? = cursor[2]
            let text: String? = cursor[3]
            let bool: Bool? = cursor[4]
            let notNull: Int = try cursor[5].unwrap()
            let withDefault: String = try cursor[6].unwrap()
            
            return .init(primaryInt: primary,
                         int: int,
                         real: real,
                         text: text,
                         bool: bool,
                         notnull: notNull,
                         withDefault: withDefault)
        }
    }
}
