
import Logging
import SQLBlueprint

public protocol PostgresConnectionProtocol: SQLConnectionProtocol, PostgresQueryableProtocol, ~Copyable where RawMessage: PostgresRawMessageProtocol, QueryMessage: PostgresQueryMessageProtocol {
    @inlinable
    func sendMessage<T: PostgresFrontendMessageProtocol>(_ message: inout T) async throws


    mutating func queryPreparedStatement<T: PostgresPreparedStatementProtocol & ~Copyable>(
        _ statement: inout T
    ) async throws -> QueryMessage.ConcreteResponse
}

// MARK: Read message
extension PostgresConnectionProtocol {
    @inlinable
    public func readMessage() async throws -> RawMessage {
        return try await RawMessage.read(on: self)
    }
}

// MARK: Send message
extension PostgresConnectionProtocol {
    @inlinable
    public func sendMessage<T: PostgresFrontendMessageProtocol>(_ message: inout T) async throws {
        #if DEBUG
        logger.info("Sending message: \(message)")
        #endif
        try await message.write(to: self)
    }
}

// MARK: Query prepared statement
extension PostgresConnectionProtocol {
    @inlinable
    public mutating func queryPreparedStatement<T: PostgresPreparedStatementProtocol & ~Copyable>(
        _ statement: inout T
    ) async throws -> QueryMessage.ConcreteResponse {
        return try await statement.prepare(on: &self)
    }
}