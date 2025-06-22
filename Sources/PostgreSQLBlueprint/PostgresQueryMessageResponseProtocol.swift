
import SQLBlueprint

public protocol PostgresQueryMessageResponseProtocol: SQLQueryMessageResponseProtocol, ~Copyable {
    func waitUntilReadyForQuery<T: PostgresConnectionProtocol & ~Copyable>(
        on connection: inout T,
        _ onMessage: (PostgresRawMessage) throws -> Void
    ) throws
}