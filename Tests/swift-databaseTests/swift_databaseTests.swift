
#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

import Testing
import Model
import PostgreSQL

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
        let decoded = try await msg.decode(on: &connection, as: UserAccount.self)
        print("decoded=\(decoded)")
    }
}