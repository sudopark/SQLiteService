//
//  File.swift
//  
//
//  Created by sudo.park on 2021/06/21.
//

import Foundation

import RxSwift
import SQLiteService



extension SQLiteService: ReactiveCompatible { }


extension Reactive where Base == SQLiteService {
    
    public func open(path: String) -> Single<Void> {
        return Single.create { [weak base] callback in
            
            guard let storage = base else { return Disposables.create() }
            nonisolated(unsafe) let callback = callback
            storage.open(path: path) { callback($0) }
            
            return Disposables.create()
        }
    }
    
    public func close() -> Single<Void> {
        
        return Single.create { [weak base] callback in
            
            guard let storage = base else { return Disposables.create() }
            nonisolated(unsafe) let callback = callback
            storage.close { callback($0) }
            
            return Disposables.create()
        }
    }
    
    
    public func run<T: Sendable>(execute: @Sendable @escaping (DataBase) throws -> T) -> Single<T> {
        
        return Single.create { [weak base] callback in
            
            guard let storage = base else { return Disposables.create() }
            nonisolated(unsafe) let callback = callback
            storage.run(execute: execute) { callback($0) }
            
            return Disposables.create()
        }
    }
    
    public func migration(upto version: Int32,
                          steps: @Sendable @escaping (Int32, DataBase) throws -> Void,
                          finalized: (@Sendable (Int32, DataBase) -> Void)? = nil) -> Single<Int32> {
        
        return Single.create { [weak base] callback in
        
            guard let storage = base else { return Disposables.create() }
            nonisolated(unsafe) let callback = callback
            storage.migrate(upto: version, steps: steps, finalized: finalized) { callback($0) }
        
            return Disposables.create()
        }
    }
}
