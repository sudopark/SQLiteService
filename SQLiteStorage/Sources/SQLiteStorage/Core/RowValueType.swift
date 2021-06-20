//
//  RowValueType.swift
//  
//
//  Created by sudo.park on 2021/06/20.
//

import Foundation


public protocol RowValueType {
    
    static func deserialize(_ cursor: OpaquePointer) throws -> Self
}
