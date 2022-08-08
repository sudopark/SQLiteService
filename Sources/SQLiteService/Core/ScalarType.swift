//
//  ScalarType.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import Foundation



// MARK: - ScalarType

public protocol ScalarType: Sendable { }

extension Bool: ScalarType {
    
    var asInt: Int32 {
        return self ? 1 : 0
    }
}

extension Int: ScalarType {
    
    var asInt64: Int64 {
        return Int64(self)
    }
    
    public var asInt32: Int32 {
        return Int32(self)
    }
}

extension Double: ScalarType { }

extension Float: ScalarType { }

extension String: ScalarType {
    
    var asNSString: NSString {
        return NSString(string: self)
    }
}

extension Array: ScalarType where Element: ScalarType { }
