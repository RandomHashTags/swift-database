
import Logging
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-COPYDATA
public struct PostgresCopyDataMessage: PostgresCopyDataMessageProtocol, @unchecked Sendable {
    public var data:ByteBuffer

    @inlinable
    public init(data: ByteBuffer) {
        self.data = data
    }
}

// MARK: Parse
extension PostgresCopyDataMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage
    ) throws -> Self {
        guard message.type == .d else {
            throw PostgresError.copyData("message type != .d")
        }
        return .init(data: message.body)
    }
}

// MARK: Payload
extension PostgresCopyDataMessage {
    @inlinable
    public func payload() -> ByteBuffer {
        let buffer = ByteBuffer(capacity: 5)
        var i = 0
        buffer.writePostgresMessageHeader(type: .d, capacity: 5, to: &i)
        buffer.copyBuffer(data.baseAddress!, count: data.count, to: &i)
        return buffer
    }
}

// MARK: Write
extension PostgresCopyDataMessage {
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
    public func copyData(logger: Logger) throws -> PostgresCopyDataMessage {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresCopyDataMessage")
        #endif
        return try PostgresCopyDataMessage.parse(message: self)
    }
}