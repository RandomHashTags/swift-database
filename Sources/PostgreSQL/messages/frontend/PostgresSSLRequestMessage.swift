
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-SSLREQUEST
public struct PostgresSSLRequestMessage: PostgresSSLRequestMessageProtocol {
    @inlinable
    public init() {
    }
}

// MARK: Payload
extension PostgresSSLRequestMessage {
    @inlinable
    public mutating func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: 8, { buffer in
            var i = 0
            buffer.writeIntBigEndian(Int32(8), to: &i)
            buffer.writeIntBigEndian(Int32(80877103), to: &i)
            try closure(buffer)
        })
    }
}

// MARK: Write
extension PostgresSSLRequestMessage {
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
    public static func sslRequest() -> PostgresSSLRequestMessage {
        return PostgresSSLRequestMessage()
    }
}