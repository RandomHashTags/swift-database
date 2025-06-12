// swift-tools-version:6.2

import PackageDescription
import CompilerPluginSupport

let traits:Set<Trait> = [
    .default(enabledTraits: ["PostgreSQL"]),

    .trait(name: "SwiftDatabaseBlueprint"),
    .trait(
        name: "SQLBlueprint",
        enabledTraits: ["SwiftDatabaseBlueprint"]
    ),
    .trait(
        name: "NoSQLBlueprint",
        enabledTraits: ["SwiftDatabaseBlueprint"]
    ),

    .trait(
        name: "MongoDBBlueprint",
        enabledTraits: ["NoSQLBlueprint"]
    ),
    .trait(
        name: "MongoDB",
        enabledTraits: ["MongoDBBlueprint"]
    ),

    .trait(
        name: "OracleBlueprint",
        enabledTraits: ["SQLBlueprint"]
    ),
    .trait(
        name: "Oracle",
        enabledTraits: ["OracleBlueprint"]
    ),

    .trait(
        name: "MicrosoftSQLBlueprint",
        enabledTraits: ["SQLBlueprint"]
    ),
    .trait(
        name: "MicrosoftSQL",
        enabledTraits: ["MicrosoftSQLBlueprint"]
    ),

    .trait(
        name: "PostgreSQLBlueprint",
        enabledTraits: ["SQLBlueprint"]
    ),
    .trait(
        name: "PostgreSQL",
        enabledTraits: ["PostgreSQLBlueprint"]
    )
]

let package = Package(
    name: "swift-database",
    products: [
        .library(
            name: "SwiftDatabaseBlueprint",
            targets: ["SwiftDatabaseBlueprint"]
        ),
    ],
    traits: traits,
    dependencies: [
        // Macros
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "601.0.1"),

        // Logging
        .package(url: "https://github.com/apple/swift-log", from: "1.6.3"),
    ],
    targets: [
        // MARK: SwiftDatabaseUtilities
        .target(
            name: "SwiftDatabaseUtilities"
        ),

        // MARK: SwiftDatabaseMacros
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

        // MARK: SwiftDatabaseBlueprint
        .target(
            name: "SwiftDatabaseBlueprint",
            dependencies: [
                "SwiftDatabaseUtilities",
                "SwiftDatabaseMacros"
            ]
        ),

        // MARK: NoSQLBlueprint
        .target(
            name: "NoSQLBlueprint",
            dependencies: [
                "SwiftDatabaseBlueprint"
            ]
        ),

        // MARK: MongoDBBlueprint
        .target(
            name: "MongoDBBlueprint",
            dependencies: [
                "NoSQLBlueprint"
            ]
        ),

        // MARK: SQLBlueprint
        .target(
            name: "SQLBlueprint",
            dependencies: [
                "SwiftDatabaseBlueprint"
            ]
        ),

        // MARK: OracleBlueprint
        .target(
            name: "OracleBlueprint",
            dependencies: [
                "SQLBlueprint"
            ]
        ),

        // MARK: MicrosoftSQLBlueprint
        .target(
            name: "MicrosoftSQLBlueprint",
            dependencies: [
                "SQLBlueprint"
            ],
        ),

        // MARK: PostgreSQLBlueprint
        .target(
            name: "PostgreSQLBlueprint",
            dependencies: [
                "SQLBlueprint"
            ]
        ),

        // MARK: MySQLBlueprint
        .target(
            name: "MySQLBlueprint",
            dependencies: [
                "SQLBlueprint"
            ]
        ),

        .testTarget(
            name: "swift-databaseTests",
            dependencies: [
                "SwiftDatabaseBlueprint",
                "NoSQLBlueprint",
                "MongoDBBlueprint",
                "SQLBlueprint",
                "OracleBlueprint",
                "MicrosoftSQLBlueprint",
                "PostgreSQLBlueprint",
                "MySQLBlueprint"
            ]
        ),
    ]
)
