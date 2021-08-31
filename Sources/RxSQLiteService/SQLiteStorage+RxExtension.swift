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
            storage.open(path: path, callback)
            
            return Disposables.create()
        }
    }
    
    public func close() -> Single<Void> {
        
        return Single.create { [weak base] callback in
            
            guard let storage = base else { return Disposables.create() }
            storage.close(callback)
            
            return Disposables.create()
        }
    }
    
    
    public func run<T>(execute: @escaping (DataBase) throws -> T) -> Single<T> {
        
        return Single.create { [weak base] callback in
            
            guard let storage = base else { return Disposables.create() }
            storage.run(execute: execute, completed: callback)
            
            return Disposables.create()
        }
    }
    
    public func migration(upto version: Int32,
                          steps: @escaping (Int32, DataBase) throws -> Void,
                          finalized: ((Int32, DataBase) -> Void)? = nil) -> Single<Int32> {
        
        return Single.create { [weak base] callback in
        
            guard let storage = base else { return Disposables.create() }
            storage.migrate(upto: version, steps: steps, finalized: finalized, completed: callback)
        
            return Disposables.create()
        }
    }
}
