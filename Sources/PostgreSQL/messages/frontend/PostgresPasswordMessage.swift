
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

extension PostgresRawMessage {
    /// MARK: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-PASSWORDMESSAGE
    public struct PasswordMessage: PostgresPasswordMessageProtocol {
        public var password:String

        public init(password: String) {
            self.password = password
        }
    }
}

// MARK: Payload
extension PostgresRawMessage.PasswordMessage {
    @inlinable
    public mutating func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        try password.withUTF8 { passwordBuffer in
            let capacity = 5 + passwordBuffer.count
            try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity, { buffer in
                buffer[0] = .p

                var i = 1
                buffer.writeIntBigEndian(Int32(capacity), to: &i)
                buffer.copyBuffer(passwordBuffer, to: &i)
                try closure(buffer)
            })
        }
    }
}

// MARK: Write
extension PostgresRawMessage.PasswordMessage {
    @inlinable
    public mutating func write<Connection: PostgresConnectionProtocol & ~Copyable>(to connection: borrowing Connection) throws {
        try payload {
            try connection.writeBuffer($0.baseAddress!, length: $0.count)
        }
    }
}