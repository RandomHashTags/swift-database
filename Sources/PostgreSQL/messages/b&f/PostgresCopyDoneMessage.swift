
import Logging
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-COPYDONE
public struct PostgresCopyDoneMessage: PostgresCopyDoneMessageProtocol {
    public init() {
    }
}

// MARK: Parse
extension PostgresCopyDoneMessage {
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .c else {
            throw PostgresError.copyDone("message type != .c")
        }
        try closure(.init())
    }
}

// MARK: Payload
extension PostgresCopyDoneMessage {
    @inlinable
    public func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: 5, { buffer in
            var i = 0
            buffer.writePostgresMessageHeader(type: .c, capacity: 5, to: &i)
            try closure(buffer)
        })
    }
}

// MARK: Write
extension PostgresCopyDoneMessage {
    @inlinable
    public mutating func write<Connection: PostgresConnectionProtocol & ~Copyable>(to connection: borrowing Connection) throws {
        try payload {
            try connection.writeBuffer($0.baseAddress!, length: $0.count)
        }
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func copyDone(logger: Logger, _ closure: (consuming PostgresCopyDoneMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresCopyDoneMessage")
        #endif
        try PostgresCopyDoneMessage.parse(message: self, closure)
    }
}