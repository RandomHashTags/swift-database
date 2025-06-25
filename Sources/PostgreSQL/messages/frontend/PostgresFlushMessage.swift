
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-FLUSH
public struct PostgresFlushMessage: PostgresFlushMessageProtocol {
    @inlinable
    public init() {
    }
}

// MARK: Payload
extension PostgresFlushMessage {
    @inlinable
    public mutating func payload() -> ByteBuffer {
        let capacity = 5
        let buffer = ByteBuffer(capacity: capacity)
        var i = 0
        buffer.writePostgresMessageHeader(type: .H, capacity: capacity, to: &i)
        return buffer
    }
}

// MARK: Write
extension PostgresFlushMessage {
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
    public static func flush() -> PostgresFlushMessage {
        return PostgresFlushMessage()
    }
}