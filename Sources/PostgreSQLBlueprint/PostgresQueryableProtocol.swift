
import SQLBlueprint

public protocol PostgresQueryableProtocol: SQLQueryableProtocol, ~Copyable where QueryMessage: PostgresQueryMessageProtocol {
}