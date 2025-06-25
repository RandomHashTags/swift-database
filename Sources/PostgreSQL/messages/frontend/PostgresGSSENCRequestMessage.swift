
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-GSSENCREQUEST
public struct PostgresGSSENCRequestMessage: PostgresGSSENCRequestMessageProtocol {
    @inlinable
    public init() {
    }
}

// MARK: Payload
extension PostgresGSSENCRequestMessage {
    @inlinable
    public mutating func payload() -> ByteBuffer {
        let buffer = ByteBuffer(capacity: 8)
        var i = 0
        buffer.writeIntBigEndian(Int32(8), to: &i)
        buffer.writeIntBigEndian(Int32(80877104), to: &i)
        return buffer
    }
}

// MARK: Write
extension PostgresGSSENCRequestMessage {
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
    public static func gssencRequest() -> PostgresGSSENCRequestMessage {
        return PostgresGSSENCRequestMessage()
    }
}