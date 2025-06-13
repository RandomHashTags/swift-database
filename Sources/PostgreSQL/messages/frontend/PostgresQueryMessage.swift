
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

extension PostgresRawMessage {
    /// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-QUERY
    public struct Query: PostgresQueryMessageProtocol {
        public var query:String

        public init(_ query: String) {
            self.query = query
        }
    }
}

// MARK: Payload
extension PostgresRawMessage.Query {
    @inlinable
    public mutating func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        try query.withUTF8 { queryBuffer in
            let capacity = 1 + 4 + queryBuffer.count + 1
            try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity, { buffer in
                buffer[0] = .Q

                var i = 1
                buffer.writeIntBigEndian(Int32(capacity), to: &i)
                buffer.copyBuffer(queryBuffer, to: &i)
                buffer[i] = 0
                try closure(buffer)
            })
        }
    }
}

// MARK: Write
extension PostgresRawMessage.Query {
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
    public static func query(_ query: String) -> Query {
        return Query(query)
    }
}