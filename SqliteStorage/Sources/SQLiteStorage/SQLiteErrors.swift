//
//  SQLiteErrors.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import Foundation


public enum SQLiteErrors: Error {
    case invalidArgument(_ reason: String)
    case step(_ reason: String)
}
