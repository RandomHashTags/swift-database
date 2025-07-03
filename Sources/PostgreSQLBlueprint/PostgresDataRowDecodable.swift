
import SwiftDatabaseBlueprint

public protocol PostgresDataRowDecodable: Sendable, ~Copyable {
    static func postgresDecode(columns: [ByteBuffer?]) throws -> Self?
}