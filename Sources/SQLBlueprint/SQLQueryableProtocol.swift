
import Logging

public protocol SQLQueryableProtocol: Sendable, ~Copyable {
    associatedtype RawMessage: SQLRawMessageProtocol
    associatedtype QueryMessage: SQLQueryMessageProtocol

    var logger: Logger { get }

    mutating func query(
        unsafeSQL: String
    ) async throws -> QueryMessage.ConcreteResponse
}