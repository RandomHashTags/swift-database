
import SQLBlueprint

public protocol PostgresQueryableProtocol: SQLQueryableProtocol, ~Copyable where RawMessage == PostgresRawMessage, QueryMessage: PostgresQueryMessageProtocol {
    @inlinable
    mutating func readUntilReadyForQuery(
        _ onMessage: (PostgresRawMessage) throws -> Void
    ) async throws
}