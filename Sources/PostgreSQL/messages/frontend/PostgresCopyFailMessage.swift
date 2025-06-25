
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-COPYFAIL
public struct PostgresCopyFailMessage: PostgresCopyFailMessageProtocol {
    public var reason:String

    @inlinable
    public init(reason: String) {
        self.reason = reason
    }
}

// MARK: Payload
extension PostgresCopyFailMessage {
    @inlinable
    public mutating func payload() -> ByteBuffer {
        return reason.withUTF8 { reasonBuffer in
            let capacity = 2 + reasonBuffer.count
            let buffer = ByteBuffer(capacity: capacity)
            var i = 0
            buffer.writePostgresMessageHeader(type: .f, capacity: capacity, to: &i)
            buffer.copyBuffer(reasonBuffer, to: &i)
            buffer[i] = 0
            return buffer
        }
    }
}

// MARK: Write
extension PostgresCopyFailMessage {
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
    public static func copyFail(reason: String) -> PostgresCopyFailMessage {
        return PostgresCopyFailMessage(reason: reason)
    }
}