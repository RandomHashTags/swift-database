// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swift-database",
    products: [
        .library(
            name: "SwiftDatabase",
            targets: ["SwiftDatabase"]
        ),
    ],
    dependencies: [
        // Macros
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.0"),
        // Logging
        .package(url: "https://github.com/apple/swift-log", from: "1.6.1"),
    ],
    targets: [
        .target(
            name: "SwiftDatabaseUtilities"
        ),
        .macro(
            name: "SwiftDatabaseMacros",
            dependencies: [
                "SwiftDatabaseUtilities",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax")
            ]
        ),

        .target(
            name: "SwiftDatabase",
            dependencies: [
                "SwiftDatabaseUtilities",
                "SwiftDatabaseMacros"
            ]
        ),

        .target(
            name: "NoSQL",
            dependencies: [
                "SwiftDatabase"
            ]
        ),
        .target(
            name: "MongoDB",
            dependencies: [
                "NoSQL"
            ]
        ),

        .target(
            name: "SQL",
            dependencies: [
                "SwiftDatabase"
            ]
        ),
        .target(
            name: "Oracle",
            dependencies: [
                "SQL"
            ]
        ),
        .target(
            name: "MicrosoftSQL",
            dependencies: [
                "SQL"
            ]
        ),
        .target(
            name: "PostgreSQL",
            dependencies: [
                "SQL"
            ]
        ),
        .target(
            name: "MySQL",
            dependencies: [
                "SQL"
            ]
        ),

        .testTarget(
            name: "swift-databaseTests",
            dependencies: ["SwiftDatabase"]
        ),
    ]
)
