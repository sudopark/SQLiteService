// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SQLiteService",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
        .tvOS(.v10),
        .watchOS(.v3)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "SQLiteService", targets: ["SQLiteService"]),
        .library(name: "RxSQLiteService", targets: ["RxSQLiteService"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.2.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(name: "SQLiteService", dependencies: []),
        .target(name: "RxSQLiteService", dependencies: ["SQLiteService", "RxSwift"]),
        .testTarget(name: "SQLiteServiceTests", dependencies: ["SQLiteService", "RxSQLiteService"]),
    ],
    swiftLanguageVersions: [.v5]
)
