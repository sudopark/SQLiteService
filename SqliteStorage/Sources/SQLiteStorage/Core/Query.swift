//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/18.
//

import Foundation


public protocol Query {
    
    func asStatement() throws -> String
}
