
public protocol SQLQueryableProtocol: Sendable, ~Copyable {
    associatedtype QueryMessage: SQLQueryMessageProtocol

    func query(unsafeSQL: String) async throws -> QueryMessage.ConcreteResponse
}