
import PostgreSQLBlueprint
import SQLBlueprint
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-CANCELREQUEST
public struct PostgresCancelRequestMessage: PostgresCancelRequestMessageProtocol {
    public var processID:Int32
    public var secretKey:Int32

    @inlinable
    public init(
        processID: Int32,
        secretKey: Int32
    ) {
        self.processID = processID
        self.secretKey = secretKey
    }
}

// MARK: Payload
extension PostgresCancelRequestMessage {
    @inlinable
    public mutating func payload() -> ByteBuffer {
        let buffer = ByteBuffer(capacity: 16)
        var i = 0
        buffer.writeIntBigEndian(Int32(16), to: &i)
        buffer.writeIntBigEndian(Int32(80877102), to: &i)
        buffer.writeIntBigEndian(processID, to: &i)
        buffer.writeIntBigEndian(secretKey, to: &i)
        return buffer
    }
}

// MARK: Write
extension PostgresCancelRequestMessage {
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
    public static func cancelRequest(processID: Int32, secretKey: Int32) -> PostgresCancelRequestMessage {
        return PostgresCancelRequestMessage(processID: processID, secretKey: secretKey)
    }
}