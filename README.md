# SQLiteService

It is a library for easier and type-safe use of sqlite in the apple device(ios/macos) environment.
A table is declared once with the ```@Table``` macro, and queries are built from its columns.

```swift
import SQLiteServiceMacros

@Table("Users")
struct UserTable {

    @Column(.primaryKey(autoIncrement: false)) var uid: String
    @Column(.notNull) var name: String
    var age: Int?
}

let service = SQLiteService()
_ = service.open(path: dbPath)
_ = service.run { try $0.insert(UserTable.self, entities: [.init(uid: "u1", name: "sudo", age: 30)]) }

let query = UserTable.selectAll { $0.age > 20 }
let users: Result<[UserTable.Entity], Error> = service.run { try $0.load(query) }
```


## Installation
Currently, only SPM is supported. The runtime deployment targets are unchanged.

| Product | Use |
|---|---|
| ```SQLiteServiceMacros``` | ```@Table``` / ```@Column``` macros. Re-exports ```SQLiteService```, so this one import is enough. Requires Swift 6. |
| ```SQLiteService``` | The core library without the macros. Use it when you do not want to build swift-syntax. |
| ```RxSQLiteService``` | RxSwift extensions. |

`SQLiteService` and `SQLiteServiceMacros` build in the Swift 6 language mode, so an entity crossing the access queue has to be `Sendable`: `RowValueType` inherits `Sendable` and the completion handler APIs take `@Sendable` closures. A hand written entity that is a non-final class or holds mutable state has to become a value type. `RxSQLiteService` stays in the Swift 5 language mode until RxSwift annotates its own API.

`SQLiteService` and `RxSQLiteService` build on Swift 5 as well - a Swift 5 toolchain resolves the package through `Package@swift-5.swift`, which declares those two products only. The `@Table` macro needs a macro capable manifest, so `SQLiteServiceMacros` is available on Swift 6 and later.


## Define a table with @Table

```swift
import SQLiteServiceMacros

@Table("Users")
struct UserTable {

    @Column(.primaryKey(autoIncrement: false)) var uid: String
    @Column(.notNull) var name: String
    var age: Int?
    @Column(.unique, .notNull) var email: String
    var phone: String?
    @Column(name: "intro") var introduction: String?
}

@Table("pets")
struct PetTable {

    @Column(.primaryKey(autoIncrement: false), .notNull) var uid: String
    @Column(.notNull, name: "owner_id") var ownerID: String
    @Column(.notNull) var name: String
}
```

The macro generates the ```Table``` conformance, a ```Columns``` enum and an ```Entity``` struct from the declaration order, so the column order and the cursor read order can not drift apart.

- Every stored instance property becomes a column, with or without ```@Column```. ```static``` / ```class``` properties are not columns.
- The SQLite data type comes from the Swift type: ```Int``` and ```Bool``` to ```.integer```, ```String``` to ```.text```, ```Double``` and ```Float``` to ```.real```. A property without a type annotation or of any other type is a compile error.
- Column attributes come only from ```@Column```. A property without it has no attributes - a non optional property is not ```NOT NULL``` by itself either.
- ```@Column(name:)``` sets the stored column name, otherwise the property name is used.
- A table declares stored properties only. A computed property or a ```willSet``` / ```didSet``` observer is a compile error, so the entity is always inferable from the declared types alone.
- ```Entity``` gets a memberwise init and the ```RowValueType``` cursor init. Its mutability follows the column type, not the table declaration, so writing ```let``` or ```var``` on a table property makes no difference: an optional column becomes a mutable ```var``` whose init argument defaults to ```nil``` and can be filled in after the entity is built, every other column becomes a ```let```.

Conversions from your domain model live in an extension of the generated ```Entity```.

```swift
extension UserTable.Entity {

    init(_ user: User) {
        self.init(uid: user.uid, name: user.name, age: user.age,
                  email: user.email, phone: user.phone, introduction: user.introduction)
    }
}
```


## How to use it

The interface of SQLiteService simply consists of open/close + run + migration. The operation that returns the Result type is synchronous, and when the Result is passed to the completion handler, it operates asynchronously. (Synchronous operations of asynchronous operation + run action are executed after the migration operation is finished internally in SQLiteService.)

The run method should be called with a closure of this type: ```(DataBase) throws -> T``` indicating what action to take and what the result type is. ```(DataBase)``` follows the ```Connection & DataBase``` protocol. Please refer to the protocol for which functions are supported. (Instead of using SQLiteService, you can directly handle ```SQLiteDataBase``` objects that conforms the ```Connection & DataBase``` protocol.)


### open and close database

```swift
let openResult: Result<Void, Error> = service.open(path: dbPath)
let closeResult: Result<Void, Error> = service.close()

service.open(path: dbPath) { result in
    print("db open result: \(result)")
}
service.close { result in
    print("db close result: \(result)")
}

// async / await
try await service.async.open(path: dbPath)
try await service.async.close()
```


### data manipulation

```swift
let table = UserTable.self
let users = (0..<10).map { UserTable.Entity(User(dummy: $0)) }

// save
// The task executed by the run method is executed in order by the serial queue,
// synchronously or asynchronously according to the request method.
service.run(execute: { try $0.insert(table, entities: users) }) { result in
    print("save users result: \(result)")
}

// load
let olderThan5 = table.selectAll { $0.age > 5 && $0.introduction == "hello" }
let loaded: Result<[UserTable.Entity], Error> = service.run { try $0.load(olderThan5) }

let user1 = table.selectAll { $0.uid == "uid:1" }
let loadedOne: Result<UserTable.Entity?, Error> = service.run { try $0.loadOne(user1) }

// update
let updateQuery = table.update { [$0.introduction == "newIntro"] }
    .where { $0.uid == "uid:1" }
_ = service.run { try $0.update(table, query: updateQuery) }

// delete
let deleteQuery = table.delete().where { $0.uid == "uid:1" }
_ = service.run { try $0.delete(table, query: deleteQuery) }

// join
let joinQuery = UserTable.selectAll()
    .innerJoin(with: PetTable.selectAll(), on: { ($0.uid, $1.ownerID) })
let mapping: (CursorIterator) throws -> (UserTable.Entity, PetTable.Entity) = { cursor in
    return (try UserTable.Entity(cursor), try PetTable.Entity(cursor))
}
let ownerAndPets = service.run { try $0.load(joinQuery, mapping: mapping) }
```


### migration

Migration statements are written by hand in an extension of the table. ```migrate(upto:steps:)``` calls each step with the current ```user_version``` until it reaches the target version.

```swift
@Table("Users")
struct UserTable {
    // ...
    var isBlocked: Bool?
}

extension UserTable {

    static func migrateStatement(for version: Int32) -> String? {
        switch version {
        case 0: return self.addColumnStatement(.isBlocked)
        default: return nil
        }
    }
}

service.migrate(upto: 1, steps: { version, database in
    try database.migrate(UserTable.self, version: version)
}) { result in
    print("migrated version: \(result)")
}
```


## Hand written Table conformance

Tables that the macro does not fit - one entity shared by several tables, for example - stay as a hand written ```Table``` conformance. It needs a ```ColumnType``` that lists the columns in order, an ```EntityType``` that reads a row from the cursor in the same order, and ```scalar(_:for:)``` that maps each column to an entity property.

```swift
import SQLiteService

struct UserTable: Table {

    enum Columns: String, TableColumn {
        case uid
        case name
        case age

        var dataType: ColumnDataType {
            switch self {
            case .uid: return .text([.primaryKey(autoIncrement: false)])
            case .name: return .text([.notNull])
            case .age: return .integer([])
            }
        }
    }

    struct Entity: RowValueType {
        let uid: String
        let name: String
        let age: Int?

        init(_ cursor: CursorIterator) throws {
            self.uid = try cursor.next().unwrap()
            self.name = try cursor.next().unwrap()
            self.age = cursor.next()
        }
    }

    typealias EntityType = Entity
    typealias ColumnType = Columns

    static var tableName: String { "Users" }

    static func scalar(_ entity: Entity, for column: Columns) -> ScalarType? {
        switch column {
        case .uid: return entity.uid
        case .name: return entity.name
        case .age: return entity.age
        }
    }
}
```

Data is stored by matching entity property values in the order of the columns from ```CaseIterable```, so the cursor reads in ```Entity.init(_:)``` must follow the same order.

For more information on how to use it, see unit tests.


**As you can see from the readme, this project has a lot of missing features and a lot of room for improvement. Feedback or contributions to the project are always welcome. 🙏**
