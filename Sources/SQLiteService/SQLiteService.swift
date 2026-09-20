//
//  SQLiteService.swift
//  
//
//  Created by sudo.park on 2021/06/19.
//

import Foundation



private extension DispatchQueue {
    
    static var defaultSerialAccessQueue: DispatchQueue {
        return .init(label: "db_access_queue:\(UUID().uuidString)", qos: .utility)
    }
}


public final class SQLiteService: @unchecked Sendable {

    private let dbConnection: Connection & DataBase
    private let serialAccessQueue: DispatchQueue
    
    let openWithReadOnly: Bool
    private static let queueKey = DispatchSpecificKey<Int>()
    private lazy var serialQueueContext: Int = unsafeBitCast(self, to: Int.self)
    
    public init(
        dbConnection: Connection & DataBase = SQLiteDataBase(),
        accessQueue: DispatchQueue? = nil,
        openWithReadOnly: Bool = false
    ) {
        self.dbConnection = dbConnection
        self.serialAccessQueue = accessQueue ?? .defaultSerialAccessQueue
        self.openWithReadOnly = openWithReadOnly
        self.serialAccessQueue.setSpecific(key: Self.queueKey, value: serialQueueContext)
    }
    
    @available(*, deprecated, message: "migrationQueue is ignored. migration runs on the access queue.")
    public convenience init(
        dbConnection: Connection & DataBase = SQLiteDataBase(),
        accessQueue: DispatchQueue? = nil,
        migrationQueue: DispatchQueue?,
        openWithReadOnly: Bool = false
    ) {
        self.init(dbConnection: dbConnection, accessQueue: accessQueue, openWithReadOnly: openWithReadOnly)
    }
    
    private func runOnAccessQueue<T>(_ action: () -> T) -> T {
        let isRunningOnSerialAccessQueue = DispatchQueue.getSpecific(key: Self.queueKey) == self.serialQueueContext
        return isRunningOnSerialAccessQueue ? action() : self.serialAccessQueue.sync(execute: action)
    }
    
    public func open(path: String) -> Result<Void, Error> {
        let isReadOnly = self.openWithReadOnly
        return self.runOnAccessQueue {
            do {
                try self.dbConnection.open(path: path, isReadOnly: isReadOnly)
                return .success(())
            } catch let error {
                return .failure(error)
            }
        }
    }
    
    public func open(path: String, _ completed: @escaping (Result<Void, Error>) -> Void) {
        
        let isReadOnly = self.openWithReadOnly
        
        self.serialAccessQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                try self.dbConnection.open(path: path, isReadOnly: isReadOnly)
                completed(.success(()))
            } catch let error {
                completed(.failure(error))
            }
        }
    }
    
    @discardableResult
    public func close() -> Result<Void, Error> {
        return self.runOnAccessQueue {
            do {
                try self.dbConnection.close()
                return .success(())
            } catch let error {
                return .failure(error)
            }
        }
    }
    
    public func close(_ completed: @escaping (Result<Void, Error>) -> Void) {
        
        self.serialAccessQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                try self.dbConnection.close()
                completed(.success(()))
            } catch let error {
                completed(.failure(error))
            }
        }
    }
}

extension SQLiteService {
    
    @discardableResult
    public func run<T>(execute: (DataBase) throws -> T) -> Result<T, Error> {
        
        return self.runOnAccessQueue {
            do {
                let result = try execute(self.dbConnection)
                return .success(result)
            } catch let error {
                return .failure(error)
            }
        }
    }
    
    @discardableResult
    public func run<T>(_ type: T.Type, execute: (DataBase) throws -> T) -> Result<T, Error> {
        return self.run(execute: execute)
    }

    public func run<T>(execute: @escaping (DataBase) throws -> T,
                       completed: @escaping (Result<T, Error>) -> Void) {
        
        self.serialAccessQueue.async { [weak self] in
            guard let connection = self?.dbConnection else { return }
            do {
                let result = try execute(connection)
                completed(.success(result))
            } catch let error {
                completed(.failure(error))
            }
        }
    }
    
    public func run<T>(_ type: T.Type,
                       execute: @escaping (DataBase) throws -> T,
                       completed: @escaping (Result<T, Error>) -> Void) {
        self.run(execute: execute, completed: completed)
    }
}


extension SQLiteService {
    
    public func migrate(
        upto version: Int32,
        steps: @escaping (Int32, DataBase) throws -> Void,
        finalized: ((Int32, DataBase) -> Void)? = nil,
        completed: @escaping (Result<Int32, Error>
    ) -> Void) {
        
        self.serialAccessQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let currentVersion = try self.dbConnection.userVersion()
                let newVersion = try self.runMigrationSteps(currentVersion: currentVersion,
                                                            upto: version,
                                                            migrationJob: steps,
                                                            finalizingJob: finalized)
                completed(.success(newVersion))
                
            } catch let error {
                completed(.failure(error))
            }
        }
    }
    
    private func runMigrationSteps(currentVersion: Int32,
                                   upto targetVersion: Int32,
                                   migrationJob: @escaping (Int32, DataBase) throws -> Void,
                                   finalizingJob: ((Int32, DataBase) -> Void)?) throws -> Int32 {
        
        guard currentVersion < targetVersion else {
            finalizingJob?(currentVersion, self.dbConnection)
            return currentVersion
        }
        try migrationJob(currentVersion, self.dbConnection)
        let nextVersion = currentVersion + 1
        try self.dbConnection.updateUserVersion(nextVersion)
        
        return try runMigrationSteps(currentVersion: nextVersion,
                                     upto: targetVersion,
                                     migrationJob: migrationJob,
                                     finalizingJob: finalizingJob)
    }
}
