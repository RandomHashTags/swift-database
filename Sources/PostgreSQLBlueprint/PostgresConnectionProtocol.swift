
import SQLBlueprint

public protocol PostgresConnectionProtocol: SQLConnectionProtocol, ~Copyable where RawMessage == PostgresRawMessage {
}