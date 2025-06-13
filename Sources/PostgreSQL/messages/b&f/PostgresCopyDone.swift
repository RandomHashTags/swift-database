
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

extension PostgresRawMessage {
    /// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-COPYDONE
    public struct PostgresCopyDone: PostgresCopyDoneMessageProtocol {
        public init() {
        }
    }
}

// MARK: Payload
extension PostgresRawMessage.PostgresCopyDone {
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
extension PostgresRawMessage.PostgresCopyDone {
    @inlinable
    public mutating func write<Connection: PostgresConnectionProtocol & ~Copyable>(to connection: borrowing Connection) throws {
        try payload {
            try connection.writeBuffer($0.baseAddress!, length: $0.count)
        }
    }
}