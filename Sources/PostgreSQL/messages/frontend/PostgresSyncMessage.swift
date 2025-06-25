
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-SYNC
public struct PostgresSyncMessage: PostgresSyncMessageProtocol {
    @inlinable
    public init() {
    }
}

// MARK: Payload
extension PostgresSyncMessage {
    @inlinable
    public mutating func payload() -> ByteBuffer {
        let capacity = 5
        let buffer = ByteBuffer(capacity: capacity)
        var i = 0
        buffer.writePostgresMessageHeader(type: .S, capacity: capacity, to: &i)
        return buffer
    }
}

// MARK: Write
extension PostgresSyncMessage {
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
    public static func sync() -> PostgresSyncMessage {
        return PostgresSyncMessage()
    }
}