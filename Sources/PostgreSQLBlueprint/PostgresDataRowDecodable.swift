
public protocol PostgresDataRowDecodable: Sendable, ~Copyable {
    static func postgresDecode(columns: [String?]) throws -> Self?
}