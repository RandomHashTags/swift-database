
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-CANCELREQUEST
public struct PostgresCancelRequestMessage: PostgresCancelRequestMessageProtocol {
    public var processID:Int32
    public var secretKey:Int32

    public init(
        processID: Int32,
        secretKey: Int32
    ) {
        self.processID = processID
        self.secretKey = secretKey
    }
}

// MARK: Payload
extension PostgresCancelRequestMessage {
    @inlinable
    public mutating func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: 16, { buffer in
            var i = 0
            buffer.writeIntBigEndian(Int32(16), to: &i)
            buffer.writeIntBigEndian(Int32(80877102), to: &i)
            buffer.writeIntBigEndian(processID, to: &i)
            buffer.writeIntBigEndian(secretKey, to: &i)
            try closure(buffer)
        })
    }
}

// MARK: Write
extension PostgresCancelRequestMessage {
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
    public static func cancelRequest(processID: Int32, secretKey: Int32) -> PostgresCancelRequestMessage {
        return PostgresCancelRequestMessage(processID: processID, secretKey: secretKey)
    }
}