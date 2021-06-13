//
//  StorageDataType.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import Foundation



// MARK: - StorageDataType

public protocol StorageDataType { }

extension Bool: StorageDataType {
    
    var asInt: Int32 {
        return self ? 1 : 0
    }
}

extension Int: StorageDataType {
    
    var asInt64: Int64 {
        return Int64(self)
    }
    
    public var asInt32: Int32 {
        return Int32(self)
    }
}

extension Double: StorageDataType { }

extension Float: StorageDataType { }

extension String: StorageDataType {
    
    var asNSString: NSString {
        return NSString(string: self)
    }
}

extension Array: StorageDataType where Element: StorageDataType { }
