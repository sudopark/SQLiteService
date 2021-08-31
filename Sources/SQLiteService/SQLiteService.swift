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
    
    static var defaultMigrationQueue: DispatchQueue {
        return .init(label: "db_migration_queue:\(UUID().uuidString)", qos: .utility)
    }
}


public class SQLiteService {

    private let dbConnection: Connection & DataBase
    private let serialAccessQueue: DispatchQueue
    private let migrationQueue: DispatchQueue
    private let accessBlockGroup = DispatchGroup()
    
    private static let queueKey = DispatchSpecificKey<Int>()
    private lazy var serialQueueContext: Int = unsafeBitCast(self, to: Int.self)
    
    public init(dbConnection: Connection & DataBase = SQLiteDataBase(),
                accessQueue: DispatchQueue? = nil,
                migrationQueue: DispatchQueue? = nil) {
        self.dbConnection = dbConnection
        self.serialAccessQueue = accessQueue ?? .defaultSerialAccessQueue
        self.migrationQueue = migrationQueue ?? .defaultMigrationQueue
        self.serialAccessQueue.setSpecific(key: Self.queueKey, value: serialQueueContext)
    }
    
    private func waitForMigrationFinishIfNeed(then action: @escaping () -> Void) {
        self.accessBlockGroup.notify(queue: self.serialAccessQueue, execute: action)
    }
    
    public func open(path: String) -> Result<Void, Error> {
        do {
            try self.dbConnection.open(path: path)
            return .success(())
        } catch let error {
            return .failure(error)
        }
    }
    
    public func open(path: String, _ completed: @escaping (Result<Void, Error>) -> Void) {
        
        self.waitForMigrationFinishIfNeed { [weak self] in
            self?.serialAccessQueue.async {
                guard let self = self else { return }
                do {
                    try self.dbConnection.open(path: path)
                    completed(.success(()))
                } catch let error {
                    completed(.failure(error))
                }
            }
        }
    }
    
    @discardableResult
    public func close() -> Result<Void, Error> {
        do {
            try self.dbConnection.close()
            return .success(())
            
        } catch let error {
            return .failure(error)
        }
    }
    
    public func close(_ completed: @escaping (Result<Void, Error>) -> Void) {
        
        self.waitForMigrationFinishIfNeed { [weak self] in
            self?.serialAccessQueue.async { [weak self] in
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
}

extension SQLiteService {
    
    @discardableResult
    public func run<T>(execute: (DataBase) throws -> T) -> Result<T, Error> {
        
        func runEexecute() -> Result<T, Error> {
            do {
                let result = try execute(self.dbConnection)
                return .success(result)
            } catch let error {
                return .failure(error)
            }
        }
        
        _ = self.accessBlockGroup.wait(wallTimeout: .distantFuture)

        let isRunningOnSerialAccessQueue = DispatchQueue.getSpecific(key: Self.queueKey) == self.serialQueueContext
        return isRunningOnSerialAccessQueue ? runEexecute() : self.serialAccessQueue.sync(execute: runEexecute)
    }

    public func run<T>(execute: @escaping (DataBase) throws -> T,
                       completed: @escaping (Result<T, Error>) -> Void) {
        
        self.waitForMigrationFinishIfNeed { [weak self] in
            self?.serialAccessQueue.async {
                guard let connection = self?.dbConnection else { return }
                do {
                    let result = try execute(connection)
                    completed(.success(result))
                } catch let error {
                    completed(.failure(error))
                }
            }
        }
    }
}


extension SQLiteService {
    
    public func migrate(upto version: Int32,
                        steps: @escaping (Int32, DataBase) throws -> Void,
                        finalized: ((Int32, DataBase) -> Void)? = nil,
                        completed: @escaping (Result<Int32, Error>) -> Void) {
        
        
        self.accessBlockGroup.enter()
        self.migrationQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let currentVersion = try self.dbConnection.userVersion()
                let newVersion = try self.runMigrationSteps(currentVersion: currentVersion,
                                                            upto: version,
                                                            migrationJob: steps,
                                                            finalizingJob: finalized)
                self.accessBlockGroup.leave()
                completed(.success(newVersion))
                
            } catch let error {
                self.accessBlockGroup.leave()
                print("errror: \(error)")
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
