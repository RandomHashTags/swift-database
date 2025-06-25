
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-GSSRESPONSE
public struct PostgresGSSResponseMessage: PostgresGSSResponseMessageProtocol {
    public var data:String // TODO: support binary format

    @inlinable
    public init(data: String) {
        self.data = data
    }
}

// MARK: Payload
extension PostgresGSSResponseMessage {
    @inlinable
    public mutating func payload() -> ByteBuffer {
        // TODO: implement
        return ByteBuffer(capacity: 0)
    }
}

// MARK: Write
extension PostgresGSSResponseMessage {
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
    public static func gssResponse(data: String) -> PostgresGSSResponseMessage {
        return PostgresGSSResponseMessage(data: data)
    }
}