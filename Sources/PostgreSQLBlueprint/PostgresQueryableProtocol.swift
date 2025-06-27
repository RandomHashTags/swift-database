
import SQLBlueprint

public protocol PostgresQueryableProtocol: SQLQueryableProtocol, ~Copyable where QueryMessage: PostgresQueryMessageProtocol {
    @inlinable
    mutating func waitUntilReadyForQuery(
        _ onMessage: (PostgresRawMessage) throws -> Void
    ) async throws
}