
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-COPYFAIL
public struct PostgresCopyFailMessage: PostgresCopyFailMessageProtocol {
    public var reason:String

    public init(reason: String) {
        self.reason = reason
    }
}

// MARK: Payload
extension PostgresCopyFailMessage {
    @inlinable
    public mutating func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        try reason.withUTF8 { reasonBuffer in
            let capacity = 2 + reasonBuffer.count
            try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity, { buffer in
                var i = 0
                buffer.writePostgresMessageHeader(type: .f, capacity: capacity, to: &i)
                buffer.copyBuffer(reasonBuffer, to: &i)
                buffer[i] = 0
                try closure(buffer)
            })
        }
    }
}

// MARK: Write
extension PostgresCopyFailMessage {
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
    public static func copyFail(reason: String) -> PostgresCopyFailMessage {
        return PostgresCopyFailMessage(reason: reason)
    }
}