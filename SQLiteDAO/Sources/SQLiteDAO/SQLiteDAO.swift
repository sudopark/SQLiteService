//
//  SQLiteDAO.swift
//  
//
//  Created by sudo.park on 2021/06/14.
//

import Foundation
import SQLite3


public protocol SQLitDAODML {
    
    func load<T: Table>(_ table: T.Type, query: Query) throws -> [T.Model]
    
    func insert<T: Table>(_ table: T.Type, models: [T.Model], shouldReplace: Bool) throws

    func update<T: Table>(_ table: T.Type, query: Query) throws
    
    func delete<T: Table>(_ table: T.Type, query: Query) throws
}
