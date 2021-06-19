//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import Foundation



// MARK: - ColumnDataAttribute

public enum ColumnDataAttribute {
    
    case primaryKey(autoIncrement: Bool)
    case notNull
    case unique
    case `default`(_ value: StorageDataType)
    
    func toString() -> String {
        switch self {
        case let .primaryKey(autoIncrement: flag):
            return flag == false ? "PRIMARY KEY" : "PRIMARY KEY AUTOINCREMENT"
        case .notNull:
            return "NOT NULL"
        case .unique:
            return "UNIQUE"
        case .default(let value):
            return "DEFAULT \(value.toString())"
        }
    }
}

// MARK: - ColumnDataType

public enum ColumnDataType {
    case integer(_ attributes: [ColumnDataAttribute])
    case text(_ attributes: [ColumnDataAttribute])
    case real(_ attributes: [ColumnDataAttribute])
    case char(_ size: Int, _ attributes: [ColumnDataAttribute])
    
    func toString() -> String {
        let prefix: String
        let attributes: [ColumnDataAttribute]
        
        switch self {
        case let .integer(attrs):
            prefix = "INTEGER"
            attributes = attrs
            
        case let .text(attrs):
            prefix = "TEXT"
            attributes = attrs
            
        case let .real(attrs):
            prefix = "REAL"
            attributes = attrs
            
        case let .char(size, attrs):
            prefix = "CHAR(\(size))"
            attributes = attrs
        }
        
        let suffix = attributes.isEmpty ? "" : " \(attributes.map{ $0.toString() }.joined(separator: " "))"
        return "\(prefix)\(suffix)"
    }
    
    var attributes: [ColumnDataAttribute] {
        switch self {
        case let .integer(attrs),
             let .text(attrs),
             let .real(attrs):
            return attrs
        case let .char(_, attrs):
            return attrs
        }
    }
}


// MARK: - TableColumn

public protocol TableColumn: RawRepresentable, CaseIterable where RawValue == String {
    
    var dataType: ColumnDataType { get }
}

extension TableColumn {
    
    func toString() -> String {
        let key = "\(self.rawValue)"
        let type = self.dataType.toString()
        return "\(key) \(type)"
    }
}
