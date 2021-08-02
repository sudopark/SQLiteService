//
//  UsageExampleTests.swift
//  
//
//  Created by sudo.park on 2021/07/31.
//

import XCTest

import SQLiteService


class UsageExampleTests: XCTestCase {
    
    private var dbPath: String!
    private var service: SQLiteService!
    
    override func setUpWithError() throws {
        let testPath = try FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("test_storage.db")
            .path
        self.dbPath = testPath
        self.service = SQLiteService()
    }
    
    override func tearDownWithError() throws {
        self.service.close()
        self.service = nil
        if let path = self.dbPath {
            try FileManager.default.removeItem(atPath: path)
        }
        self.dbPath = nil
    }
}


// MARK: - open database

extension UsageExampleTests {
    
    private func openDatabaseAndCloseExample() {
        
        let openResult: Result<Void, Error> = self.service.open(path: self.dbPath)
        print("db open result: \(openResult)")
        
        let closeResult: Result<Void, Error> = self.service.close()
        print("db close result: \(closeResult)")
        
        
        self.service.open(path: self.dbPath) { result in
            print("db open result: \(result)")
        }
        
        self.service.close { result in
            print("db close result: \(result)")
        }
    }
}


// MARK: define table

struct UserTable: Table {
    
    // Define table column
    enum Columns: String, TableColumn {
        case uid
        case name
        case age
        case email
        case phone
        case introduction = "intro"
    
        // define each column data type
        var dataType: ColumnDataType {
            switch self {
            case .uid: return .text([.primaryKey(autoIncrement: false)])
            case .name: return .text([.notNull])
            case .age: return .integer([])
            case .email: return .text([.unique, .notNull])
            case .phone: return .text([])
            case .introduction: return .text([])
            }
        }
    }
    
    // Define Entity that conforms to RowValueType protocol.
    struct Entiity: RowValueType {
        let uid: String
        let name: String
        let age: Int?
        let email: String
        let phone: String?
        let introduction: String?
        
        init(_ cursor: CursorIterator) throws {
            self.uid = try cursor.next().unwrap()
            self.name = try cursor.next().unwrap()
            self.age = cursor.next()
            self.email = try cursor.next().unwrap()
            self.phone = cursor.next()
            self.introduction = cursor.next()
        }
    }
    
    typealias EntityType = Entiity
    typealias ColumnType = Columns
    
    static var tableName: String { "Users" }
    
    // mapping each column with model property
    static func scalar(_ entity: Entiity, for column: Columns) -> ScalarType? {
        switch column {
        case .uid: return entity.uid
        case .name: return entity.name
        case .age: return entity.age
        case .email: return entity.email
        case .phone: return entity.phone
        case .introduction: return entity.introduction
        }
    }
}

struct User {
    let uid: String
    let name: String
    var age: Int?
    let email: String
    var phone: String?
    var introduction: String?
    
    init(dummy index: Int) {
        self.uid = "uid:\(index)"
        self.name = "name:\(index)"
        self.age = index % 2 == 0 ? nil: index
        self.email = "email:\(index)"
        self.introduction = ["hello", "world", "!"].randomElement()
    }
}

extension UserTable.Entiity {
    
    init(_ user: User) {
        self.uid = user.uid
        self.name = user.name
        self.age = user.age
        self.email = user.email
        self.phone = user.phone
        self.introduction = user.introduction
    }
}


// MARK: - save and load

extension UsageExampleTests {

    func testSaveDataUsaga() {
        
        let expect = expectation(description: "save users")
        _ = self.service.open(path: self.dbPath)
        
        let users = (0..<10).map{ User(dummy: $0) }
        let entities = users.map{ UserTable.Entiity($0) }
        
        /**
         The  task executed by the run method can be sequentially executed synchronously/asynchronously according to the request method by the serial queue.
         */
        self.service.run(execute: { try $0.insert(UserTable.self, entities: entities) }) { result in
            print("save users result: \(result)")
            expect.fulfill()
        }
        
        self.wait(for: [expect], timeout: 0.01)
    }
    
    func testLoadDataUsage() {
        
        let users = (0..<10).map{ User(dummy: $0) }
        let entities = users.map{ UserTable.Entiity($0) }
        
        let table = UserTable.self
        
        _ = self.service.open(path: self.dbPath)
        _ = self.service.run(execute: { try $0.insert(table, entities: entities) })
        
        let query1 = table.selectAll{ $0.age > 5 }
        let result1: Result<[UserTable.Entiity], Error> = self.service.run(execute: { try $0.load(query1) })
        print("load users older than 5 result \(result1)")
        
        
        let query2 = table.selectAll{ $0.age > 5 && $0.introduction == "hello" }
        let result2: Result<[UserTable.Entiity], Error> = self.service.run(execute: { try $0.load(query2) })
        print("load result: \(result2)")
        
        let query3 = table.selectAll{ $0.uid == "uid:1" }
        let result3: Result<UserTable.Entiity?, Error> = self.service.run(execute: { try $0.loadOne(query3) })
        print("load user 1 result: \(result3)")
        
        let query4 = table.selectAll()
        let result4: Result<[UserTable.Entiity], Error> = self.service.run(execute: { try $0.load(query4) })
        print("load all users result: \(result4)")
    }
    
    func testUpdateUsage() {
        
        let expect = expectation(description: "update user introduction")
        let table = UserTable.self
        
        var oldUser = User(dummy: 1)
        oldUser.introduction = "old_introduction"
        _ = self.service.open(path: self.dbPath)
        _ = self.service.run(execute: { try $0.insert(table, entities: [.init(oldUser)]) })
        
        let updateQuery = table.update { [$0.introduction == "newIntro"]}
        _ = self.service.run(execute: { try $0.update(table, query: updateQuery) })
        
        let selectQuery = table.selectAll{ $0.uid == "uid:1" }
        self.service.run(execute: { try $0.loadOne(selectQuery) }) { (result: Result<UserTable.Entiity?, Error>) in
            guard case let .success(user) = result, let updatedUser = user else { return }
            print("updated user intro: \(updatedUser.introduction)")
            expect.fulfill()
        }
        
        self.wait(for: [expect], timeout: 0.01)
    }
    
    func testDeleteUsage() {
        let expect = expectation(description: "delete user1")
        let table = UserTable.self
        
        let users = (0..<10).map{ User(dummy: $0) }
        let entities = users.map{ UserTable.Entiity($0) }
        
        _ = self.service.open(path: self.dbPath)
        _ = self.service.run(execute: { try $0.insert(table, entities: entities) })
        
        let deleteQuery = table.delete().where{ $0.uid == "uid:1" }
        self.service.run(execute: { try $0.delete(table, query: deleteQuery) }) { result in
            print("delete result: \(result)")
            expect.fulfill()
        }
        
        self.wait(for: [expect], timeout: 0.01)
    }
}



extension UsageExampleTests {
    
    // MARK: - join query
    
    // degine pet table
    struct PetTable: Table {
        
        enum Columns: String, TableColumn {
            case uid
            case ownerID = "owner_id"
            case name
            
            var dataType: ColumnDataType {
                switch self {
                case .uid: return .text([.primaryKey(autoIncrement: false), .notNull])
                case .ownerID: return .text([.notNull])
                case .name: return .text([.notNull])
                }
            }
        }
        
        struct Entity: RowValueType {
            let uid: String
            let ownerID: String
            let name: String
            
            init(_ cursor: CursorIterator) throws {
                self.uid = try cursor.next().unwrap()
                self.ownerID = try cursor.next().unwrap()
                self.name = try cursor.next().unwrap()
            }
            
            init(uid: String, ownerID: String, name: String) {
                self.uid = uid
                self.ownerID = ownerID
                self.name = name
            }
        }
        
        static var tableName: String { "pets" }
        typealias ColumnType = Columns
        typealias EntityType = Entity
        
        static func scalar(_ entity: Entity, for column: Columns) -> ScalarType? {
            switch column {
            case .uid: return entity.uid
            case .ownerID: return entity.ownerID
            case .name: return entity.name
            }
        }
    }
    
    
    func testJoinQueryUsage() {

        let users = (0..<10).map{ User(dummy: $0) }.map{ UserTable.Entiity($0) }
        let pets: [PetTable.Entity] = [
            .init(uid: "p0", ownerID: "uid:1", name: "foo"),
            .init(uid: "p1", ownerID: "uid:3", name: "bar")
        ]
        
        _ = self.service.open(path: self.dbPath)
        _ = self.service.run(execute: { try $0.insert(UserTable.self, entities: users) })
        _ = self.service.run(execute: { try $0.insert(PetTable.self, entities: pets) })
        
        let allUserQuery = UserTable.selectAll()
        let allpetsQuery = PetTable.selectAll()
        let joinQuery = allUserQuery.innerJoin(with: allpetsQuery, on: { ($0.uid, $1.ownerID) })
        
        typealias UserAndPetPair = (UserTable.Entiity, PetTable.Entity)
        let mapping: (CursorIterator) throws -> UserAndPetPair? = { cursor in
            return (try UserTable.Entiity(cursor), try PetTable.Entity(cursor))
        }
        let result = self.service.run(execute: { try $0.load(joinQuery, mapping: mapping) })
        let petOwnerAndPets = try? result.get()
        print("pet owner and pet: \(petOwnerAndPets)")
        XCTAssertEqual(petOwnerAndPets?.count, 2)
    }
}
