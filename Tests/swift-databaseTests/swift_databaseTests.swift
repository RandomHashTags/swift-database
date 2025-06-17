
#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

import Testing
import Model
import ModelUtilities
import PostgreSQL
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

@Test
func example() async throws {
    var connection = PostgresConnection()
    try await connection.establish(address: "127.0.0.1", port: 5432, user: "postgres", database: "postgres")
    let response = try await connection.query(unsafeSQL: "SELECT * FROM test;")
    print(response)
}

@Model(
    supportedDatabases: [.postgreSQL],
    schema: "users",
    selectFilters: [
        (["id"], ModelCondition(name: "passwordIsPASSWORD", firstCondition: .init(field: "password", operator: .equal, value: "'PASSWORD'")))
    ],
    revisions: [
        ModelRevision(
            version: (1, 0, 0),
            fields: [
                ("id", "UInt64"),
                ("created", "Date"),
                ("deleted", "Date"),
                ("email", "String"),
                ("password", "String")
            ]
        )
    ]
)
struct UserAccount: Model {
    typealias IDValue = UInt64

    var id:IDValue?

    var created:Date?
    var deleted:Date?

    var email:String
    var password:String
}