
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-PASSWORDMESSAGE
public struct PostgresPasswordMessage: PostgresPasswordMessageProtocol {
    public var password:String

    @inlinable
    public init(password: String) {
        self.password = password
    }
}

// MARK: Payload
extension PostgresPasswordMessage {
    @inlinable
    public mutating func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        try password.withUTF8 { passwordBuffer in
            let capacity = 5 + passwordBuffer.count
            try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity, { buffer in
                var i = 0
                buffer.writePostgresMessageHeader(type: .p, capacity: capacity, to: &i)
                buffer.copyBuffer(passwordBuffer, to: &i)
                try closure(buffer)
            })
        }
    }
}

// MARK: Write
extension PostgresPasswordMessage {
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
    public static func password(_ password: String) -> PostgresPasswordMessage {
        return PostgresPasswordMessage(password: password)
    }
}