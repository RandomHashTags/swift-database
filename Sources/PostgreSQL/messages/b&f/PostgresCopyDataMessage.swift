
import Logging
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-COPYDATA
public struct PostgresCopyDataMessage: PostgresCopyDataMessageProtocol {
    public init() {
    }
}

// MARK: Parse
extension PostgresCopyDataMessage {
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .d else {
            throw PostgresError.copyData("message type != .d")
        }
        try closure(.init())
    }
}

// MARK: Payload
extension PostgresCopyDataMessage {
    @inlinable
    public func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        // TODO: fix
        try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: 5, { buffer in
            var i = 0
            buffer.writePostgresMessageHeader(type: .d, capacity: 5, to: &i)
            try closure(buffer)
        })
    }
}

// MARK: Write
extension PostgresCopyDataMessage {
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
    public func copyData(logger: Logger, _ closure: (consuming PostgresCopyDataMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresCopyDataMessage")
        #endif
        try PostgresCopyDataMessage.parse(message: self, closure)
    }
}