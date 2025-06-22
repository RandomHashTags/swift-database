
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
import SQLBlueprint
import SwiftDatabaseBlueprint

@Test
func example() async throws {
    var connection = PostgresConnection()
    try await connection.establish(address: "127.0.0.1", port: 5432, user: "postgres", database: "postgres")
    /*let migrationResponse = try await connection.query(unsafeSQL: UserAccount.PostgresMigrations.create)
    print("migrationResponse=\(migrationResponse)")
    let migration2Response = try await connection.query(unsafeSQL: UserAccount.PostgresMigrations.incremental_v0_0_2)
    print("migration2Response=\(migration2Response)")
    let insertResponse = try await UserAccount.PostgresPreparedStatements.insert.prepare(on: connection)
    print("insertResponse=\(insertResponse)")*/
    let user = UserAccount(created: Date.now, email: "imrandomhashtags@gmail.com", password: "test", test2: false)
    let response = try await user.create(on: connection)
    print(response)
}

@Model(
    supportedDatabases: [.postgreSQL],
    schema: "users",
    selectFilters: [
        (["id"], .init(name: "passwordIsPASSWORD", firstCondition: .init(field: "password", operator: .equal, value: "PASSWORD")))
    ],
    revisions: [
        .init(
            version: (0, 0, 1),
            addedFields: [
                .init(
                    name: "id",
                    constraints: [.primaryKey],
                    postgresDataType: .bigserial
                ),
                .init(
                    name: "created",
                    postgresDataType: .timestampWithTimeZone(precision: 0)
                ),
                .init(
                    name: "deleted",
                    constraints: [],
                    postgresDataType: .timestampWithTimeZone(precision: 0)
                ),
                .init(
                    name: "email",
                    postgresDataType: .characterVarying(count: 255)
                ),
                .init(
                    name: "password",
                    postgresDataType: .characterVarying(count: 255)
                )
            ],
            removedFields: ["loop"]
        ),
        .init(
            version: (0, 0, 2),
            addedFields: [
                .init(
                    name: "test2",
                    postgresDataType: .boolean,
                    defaultValue: false
                )
            ]
        )
    ]
)
struct UserAccount: Model {
    typealias IDValue = Int64

    var id:IDValue?

    var created:Date
    var deleted:Date?

    var email:String
    var password:String

    var test2:Bool
}