//
//  RowValueType.swift
//  
//
//  Created by sudo.park on 2021/06/20.
//

import Foundation

// MARK: - CursorInterator

public class CursorIterator {
    
    private let pointer: OpaquePointer
    private var index = 0
    init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    public func next<T: ScalarType>() -> T? {
        defer {
            self.index += 1
        }
        return self.pointer[index]
    }
}


// MARK: - RowValuetype

public protocol RowValueType {
    
    init(_ cursor: CursorIterator) throws
}
