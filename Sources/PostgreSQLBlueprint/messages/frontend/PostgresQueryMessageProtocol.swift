
import SQLBlueprint

public protocol PostgresQueryMessageProtocol: SQLQueryMessageProtocol, PostgresFrontendMessageProtocol, ~Copyable {
    associatedtype ConcreteResponse
}