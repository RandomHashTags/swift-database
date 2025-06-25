
import Logging
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-COPYDONE
public struct PostgresCopyDoneMessage: PostgresCopyDoneMessageProtocol {
    @inlinable
    public init() {
    }
}

// MARK: Parse
extension PostgresCopyDoneMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage
    ) throws -> Self {
        guard message.type == .c else {
            throw PostgresError.copyDone("message type != .c")
        }
        return .init()
    }
}

// MARK: Payload
extension PostgresCopyDoneMessage {
    @inlinable
    public func payload() -> ByteBuffer {
        let buffer = ByteBuffer(capacity: 5)
        var i = 0
        buffer.writePostgresMessageHeader(type: .c, capacity: 5, to: &i)
        return buffer
    }
}

// MARK: Write
extension PostgresCopyDoneMessage {
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
    public func copyDone(logger: Logger) throws -> PostgresCopyDoneMessage {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresCopyDoneMessage")
        #endif
        return try PostgresCopyDoneMessage.parse(message: self)
    }
}