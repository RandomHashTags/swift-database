
public protocol SQLQueryableProtocol: Sendable, ~Copyable {
    associatedtype QueryMessage: SQLQueryMessageProtocol

    mutating func query(unsafeSQL: String) async throws -> QueryMessage.ConcreteResponse
}