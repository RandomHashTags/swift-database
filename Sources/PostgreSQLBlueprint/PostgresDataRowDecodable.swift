
public protocol PostgresDataRowDecodable: Sendable, ~Copyable {
    init?(columns: [String?]) throws
}