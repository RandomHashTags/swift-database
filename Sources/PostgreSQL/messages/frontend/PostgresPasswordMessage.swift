
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-PASSWORDMESSAGE
public struct PostgresPasswordMessage: PostgresPasswordMessageProtocol {
    public var password:String

    @inlinable
    public init(password: String) {
        self.password = password
    }
}

// MARK: Payload
extension PostgresPasswordMessage {
    @inlinable
    public mutating func payload() -> ByteBuffer {
        return password.withUTF8 { passwordBuffer in
            let capacity = 5 + passwordBuffer.count
            let buffer = ByteBuffer(capacity: capacity)
            var i = 0
            buffer.writePostgresMessageHeader(type: .p, capacity: capacity, to: &i)
            buffer.copyBuffer(passwordBuffer, to: &i)
            return buffer
        }
    }
}

// MARK: Write
extension PostgresPasswordMessage {
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
    public static func password(_ password: String) -> PostgresPasswordMessage {
        return PostgresPasswordMessage(password: password)
    }
}