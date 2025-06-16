
import Logging
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-COPYDATA
public struct PostgresCopyDataMessage: PostgresCopyDataMessageProtocol, @unchecked Sendable {
    public var data:UnsafeMutableBufferPointer<UInt8>

    @inlinable
    public init(data: UnsafeMutableBufferPointer<UInt8>) {
        self.data = data
    }
}

// MARK: Parse
extension PostgresCopyDataMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .d else {
            throw PostgresError.copyData("message type != .d")
        }
        let length:Int32 = message.body.loadUnalignedIntBigEndian() - 4
        try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: Int(length), { buffer in
            var i = 0
            buffer.copyBuffer(message.body, offset: 4, count: Int(length), to: &i)
            try closure(.init(data: buffer))
        })
    }
}

// MARK: Payload
extension PostgresCopyDataMessage {
    @inlinable
    public func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: 5, { buffer in
            var i = 0
            buffer.writePostgresMessageHeader(type: .d, capacity: 5, to: &i)
            buffer.copyBuffer(data, to: &i)
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