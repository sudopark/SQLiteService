// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

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
        .library(name: "SQLiteServiceMacros", targets: ["SQLiteServiceMacros"]),
        .library(name: "RxSQLiteService", targets: ["RxSQLiteService"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.2.0")),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "509.0.0"..<"603.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(name: "SQLiteService", dependencies: []),
        .macro(
            name: "SQLiteServiceMacrosPlugin",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(name: "SQLiteServiceMacros", dependencies: ["SQLiteService", "SQLiteServiceMacrosPlugin"]),
        .target(
            name: "RxSQLiteService",
            dependencies: ["SQLiteService", "RxSwift"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(name: "SQLiteServiceTests", dependencies: ["SQLiteService", "SQLiteServiceMacros", "RxSQLiteService"]),
        .testTarget(
            name: "SQLiteServiceMacrosTests",
            dependencies: [
                "SQLiteServiceMacrosPlugin",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
