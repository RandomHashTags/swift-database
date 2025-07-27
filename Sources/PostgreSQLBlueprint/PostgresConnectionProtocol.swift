
import Logging
import SQLBlueprint

public protocol PostgresConnectionProtocol: SQLConnectionProtocol, PostgresQueryableProtocol, ~Copyable where RawMessage: PostgresRawMessageProtocol, QueryMessage: PostgresQueryMessageProtocol {
    @inlinable
    func sendMessage(_ message: inout some PostgresFrontendMessageProtocol) async throws


    mutating func queryPreparedStatement(
        _ statement: inout some PostgresPreparedStatementProtocol & ~Copyable
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
    public func sendMessage(_ message: inout some PostgresFrontendMessageProtocol) async throws {
        #if DEBUG
        logger.info("Sending message: \(message)")
        #endif
        try await message.write(to: self)
    }
}

// MARK: Query prepared statement
extension PostgresConnectionProtocol {
    @inlinable
    public mutating func queryPreparedStatement(
        _ statement: inout some PostgresPreparedStatementProtocol & ~Copyable
    ) async throws -> QueryMessage.ConcreteResponse {
        return try await statement.prepare(on: &self)
    }
}