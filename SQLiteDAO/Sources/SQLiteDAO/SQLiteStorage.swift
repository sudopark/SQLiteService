//
//  SQLiteStorage.swift
//  
//
//  Created by sudo.park on 2021/06/14.
//

import Foundation
import SQLite3


public protocol SQLiteStorage {
    
    func count<T: Table>(_ table: T.Type)
}
