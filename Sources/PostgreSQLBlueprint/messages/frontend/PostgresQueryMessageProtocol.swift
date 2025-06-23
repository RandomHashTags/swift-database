
import SQLBlueprint

public protocol PostgresQueryMessageProtocol: SQLQueryMessageProtocol, PostgresFrontendMessageProtocol, ~Copyable where ConcreteResponse: PostgresQueryMessageResponseProtocol {
}