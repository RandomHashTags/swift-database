
public protocol SQLQueryMessageProtocol: Sendable, ~Copyable {
    associatedtype ConcreteResponse: SQLQueryMessageResponseProtocol
}