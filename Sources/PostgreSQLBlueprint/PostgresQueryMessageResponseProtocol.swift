
import Logging
import SQLBlueprint

public protocol PostgresQueryMessageResponseProtocol: SQLQueryMessageResponseProtocol, ~Copyable {
    static func parse(
        logger: Logger,
        msg: PostgresRawMessage,
        _ closure: (borrowing Self) throws -> Void
    ) throws

    func waitUntilReadyForQuery<T: PostgresConnectionProtocol & ~Copyable>(
        on connection: inout T,
        _ onMessage: (PostgresRawMessage) throws -> Void
    ) throws
}