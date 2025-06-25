
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

@Test(.timeLimit(.minutes(1)))
func example() async throws {
    var connection = PostgresConnection()
    try await connection.establish(address: "127.0.0.1", port: 5432, user: "postgres", database: "postgres")
    /*let migrationResponse = try await connection.query(unsafeSQL: UserAccount.PostgresMigrations.createTable).requireNotError()
    print("migrationResponse=\(migrationResponse)")
    let migration2Response = try await connection.query(unsafeSQL: UserAccount.PostgresMigrations.incremental_v0_0_2).requireNotError()
    print("migration2Response=\(migration2Response)")
    let insertResponse = try await UserAccount.PostgresPreparedStatements.insert.prepare(on: &connection).requireNotError()
    print("insertResponse=\(insertResponse)")
    let user = UserAccount(id: -1, created: Date.now, email: "imrandomhashtags@gmail.com", password: "test", test2: false)
    let userCreateResponse = try await user.create(on: &connection)
    print("userCreateResponse=\(userCreateResponse)")*/

    let preparedResponse = try await UserAccount.PostgresPreparedStatements.selectAll.prepare(on: &connection).requireNotError()
    print("preparedResponse=\(preparedResponse)")
    let response = try await UserAccount.PostgresPreparedStatements.selectAll.execute(on: &connection).requireNotError()
    if case let .rowDescription(msg) = response {
        let decoded = try msg.decode(on: &connection, as: UserAccount.self)
        print("decoded=\(decoded)")
    }
}

@Model(
    supportedDatabases: [.postgreSQL],
    schema: "public",
    table: "users",
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
                    postgresDataType: .timestampNoTimeZone(precision: 0)
                ),
                .init(
                    name: "deleted",
                    constraints: [],
                    postgresDataType: .timestampNoTimeZone(precision: 0)
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
        )/*,
        .init(
            version: (0, 0, 3),
            removedFields: ["test2"]
        )*/
    ]
)
struct UserAccount: Model {
    typealias IDValue = Int64

    var id:IDValue

    var created:Date
    var deleted:Date?

    var email:String
    var password:String

    var test2:Bool
}

extension UserAccount: PostgresDataRowDecodable {
    static func postgresDecode(columns: [String?]) throws -> Self? {
        guard columns.count == 6 else { return nil }
        guard let id = IDValue(columns[0]!) else { return nil }
        let created = try Date.postgresDecode(columns[1]!, as: .timestampNoTimeZone(precision: 0)) ?? Date.now
        let deleted:Date?
        if let v = columns[2] {
            deleted = try Date.postgresDecode(v, as: .timestampNoTimeZone(precision: 0)) ?? Date.now
        } else {
            deleted = nil
        }
        let email = columns[3]!
        let password = columns[4]!
        let test2 = columns[5]!.first == "t"
        return .init(id: id, created: created, deleted: deleted, email: email, password: password, test2: test2)
    }
}