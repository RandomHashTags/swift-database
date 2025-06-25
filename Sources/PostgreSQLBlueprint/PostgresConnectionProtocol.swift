
import Logging
import SQLBlueprint
import SwiftDatabaseBlueprint

public protocol PostgresConnectionProtocol: SQLConnectionProtocol, PostgresQueryableProtocol, ~Copyable where RawMessage == PostgresRawMessage, QueryMessage: PostgresQueryMessageProtocol {
    @inlinable
    func readMessage() async throws -> RawMessage

    @inlinable
    func sendMessage<T: PostgresFrontendMessageProtocol>(_ message: inout T) async throws


    @inlinable
    mutating func waitUntilReadyForQuery(
        _ onMessage: (PostgresRawMessage) throws -> Void
    ) async throws

    mutating func queryPreparedStatement<T: PostgresPreparedStatementProtocol & ~Copyable>(
        _ statement: inout T
    ) async throws -> QueryMessage.ConcreteResponse
}

// MARK: Read message
extension PostgresConnectionProtocol {
    @inlinable
    public func readMessage() async throws -> RawMessage {
        let headerBuffer = await receive(length: 5)
        guard headerBuffer.count == 5 else {
            throw PostgresError.readMessage("headerBuffer.count (\(headerBuffer.count)) != 5")
        }
        let type = headerBuffer[0]
        let length:Int32 = headerBuffer.loadUnalignedIntBigEndian(offset: 1) - 4
        let body = await receive(length: Int(length))
        #if DEBUG
        logger.info("Received message of type \(type) with body of length \(length)")
        #endif
        return RawMessage(type: type, bodyCount: length, body: body)
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