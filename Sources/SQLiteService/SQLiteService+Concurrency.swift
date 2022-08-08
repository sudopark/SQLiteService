//
//  SQLiteService+Concurrency.swift
//  
//
//  Created by sudo.park on 2022/03/26.
//

import Foundation


@available(iOS 13.0.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
public extension SQLiteService {
    
    struct Concurrency: Sendable {
        private let sqlteService: SQLiteService
        
        init(_ service: SQLiteService) {
            self.sqlteService = service
        }
    }
    
    var async: Concurrency {
        return Concurrency(self)
    }
}


// MARK: - open & close with aync/wait

@available(iOS 13.0.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
extension SQLiteService.Concurrency {
    
    public func open(path: String) async throws {
        return try await withCheckedThrowingContinuation { continutation in
            
            self.sqlteService.open(path: path) { result in
                continutation.resume(with: result)
            }
        }
    }
    
    public func close() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            
            self.sqlteService.close { result in
                continuation.resume(with: result)
            }
        }
    }
}


// MARK: - run with aync/wait

@available(iOS 13.0.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
extension SQLiteService.Concurrency {
    
    public func run<T>(execute: @escaping (DataBase) throws -> T) async throws -> T {
        
        return try await withCheckedThrowingContinuation { continuation in
            
            self.sqlteService.run(execute: execute) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func run<T>(_ type: T.Type, execute: @escaping (DataBase) throws -> T) async throws -> T {
        
        return try await withCheckedThrowingContinuation { continuation in
            
            self.sqlteService.run(type, execute: execute) { result in
                continuation.resume(with: result)
            }
        }
    }
}


// MARK: - migrate with aync/wait

@available(iOS 13.0.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
extension SQLiteService.Concurrency {
    
    public func migrate(
        upto version: Int32,
        steps: @escaping (Int32, DataBase) throws -> Void,
        finalized: ((Int32, DataBase) -> Void)? = nil
    ) async throws -> Int32 {
        
        return try await withCheckedThrowingContinuation { continuation in
            
            self.sqlteService.migrate(upto: version, steps: steps, finalized: finalized) { result in
                continuation.resume(with: result)
            }
        }
    }
}
