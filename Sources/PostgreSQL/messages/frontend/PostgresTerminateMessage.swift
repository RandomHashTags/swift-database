
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-TERMINATE
public struct PostgresTerminateMessage: PostgresTerminateMessageProtocol {
    @inlinable
    public init() {
    }
}

// MARK: Payload
extension PostgresTerminateMessage {
    @inlinable
    public mutating func payload() -> ByteBuffer {
        let capacity = 5
        let buffer = ByteBuffer(capacity: capacity)
        var i = 0
        buffer.writePostgresMessageHeader(type: .X, capacity: capacity, to: &i)
        return buffer
    }
}

// MARK: Write
extension PostgresTerminateMessage {
    @inlinable
    public mutating func write<Connection: PostgresConnectionProtocol & ~Copyable>(
        to connection: borrowing Connection
    ) async throws {
        try await connection.writeBuffer(payload())
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public static func terminate() -> PostgresTerminateMessage {
        return PostgresTerminateMessage()
    }
}