import Testing
import PostgreSQL
import SwiftDatabaseBlueprint

@Test
func example() async throws {
    var connection = PostgresConnection()
    try await connection.establish(address: "127.0.0.1", port: 5432, user: "postgres", database: "postgres")
    let response = try await connection.query("SELECT * FROM test;")
    print(response)
}