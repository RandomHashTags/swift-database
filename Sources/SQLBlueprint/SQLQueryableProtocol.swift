
import Logging

public protocol SQLQueryableProtocol: Sendable, ~Copyable {
    associatedtype RawMessage: SQLRawMessageProtocol
    associatedtype QueryMessage: SQLQueryMessageProtocol

    var logger: Logger { get }

    mutating func query(
        unsafeSQL: String,
        _ onMessage: (RawMessage) throws -> Void
    ) async throws -> QueryMessage.ConcreteResponse
}