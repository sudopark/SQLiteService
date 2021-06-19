//
//  SQLiteErrors.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import Foundation


public enum SQLiteErrors: Error {
    case open(_ message: String)
    case close
    case invalidArgument(_ message: String)
    case prepare(_ message: String)
    case step(_ message: String)
    case transation(_ message: String)
    case migration(_ message: String)
}
