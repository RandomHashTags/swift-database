
import SQLBlueprint

public protocol PostgresTransactionProtocol: SQLTransactionProtocol, ~Copyable where RawMessage == PostgresRawMessage, QueryMessage: PostgresQueryMessageProtocol {
}