
#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

import Testing
import Models
import PostgreSQL

@Test(.timeLimit(.minutes(1)))
func example() async throws {
    var connection = PostgresConnection()
    try await connection.establish(address: "127.0.0.1", port: 5432, user: "postgres", database: "postgres")
    /*let migrationResponse = try await connection.query(unsafeSQL: UserAccount.PostgresMigrations.createTable).requireNotError()
    print("migrationResponse=\(migrationResponse)")
    let migration2Response = try await connection.query(unsafeSQL: UserAccount.PostgresMigrations.incremental_v2).requireNotError()
    print("migration2Response=\(migration2Response)")*/
    /*let insertResponse = try await UserAccount.PostgresPreparedStatements.insertReturning.prepare(on: &connection).requireNotError()
    print("insertResponse=\(insertResponse)")
    var user = UserAccount(id: -1, email: "poopy@outlook.com", password: "test2", country: 69, test2: true)
    let before = user
    user = try await user.create(on: &connection)
    print("user before=\(before)\nuser after=\(user)")*/

    let preparedResponse = try await UserAccount.PostgresPreparedStatements.selectAll.prepare(on: &connection).requireNotError()
    print("preparedResponse=\(preparedResponse)")
    let response = try await UserAccount.PostgresPreparedStatements.selectAll.execute(on: &connection).requireNotError()
    if let msg = response.asRowDescription() {
        let users = try await msg.decode(on: &connection, as: UserAccount.self)
        for user in users {
            if let user {
                print("user id=\(user.id);country=\(user.country)")
            }
        }
    }
}