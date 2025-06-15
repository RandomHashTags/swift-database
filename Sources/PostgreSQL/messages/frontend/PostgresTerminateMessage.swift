
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

extension PostgresRawMessage {
    /// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-TERMINATE
    public struct Terminate: PostgresTerminateMessageProtocol {
        public init() {
        }
    }
}

// MARK: Payload
extension PostgresRawMessage.Terminate {
    @inlinable
    public mutating func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        let capacity = 5
        try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity, { buffer in
            var i = 0
            buffer.writePostgresMessageHeader(type: .X, capacity: capacity, to: &i)
            try closure(buffer)
        })
    }
}

// MARK: Write
extension PostgresRawMessage.Terminate {
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
    public static func terminate() -> Terminate {
        return Terminate()
    }
}