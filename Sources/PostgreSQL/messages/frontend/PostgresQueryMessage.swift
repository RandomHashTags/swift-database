
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-QUERY
public struct PostgresQueryMessage: PostgresQueryMessageProtocol {
    public var sql:String

    public init(_ sql: String) {
        self.sql = sql
    }
}

// MARK: Payload
extension PostgresQueryMessage {
    @inlinable
    public mutating func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        try sql.withUTF8 { sqlBuffer in
            let capacity = 5 + sqlBuffer.count + 1
            try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity, { buffer in
                var i = 0
                buffer.writePostgresMessageHeader(type: .Q, capacity: capacity, to: &i)
                buffer.copyBuffer(sqlBuffer, to: &i)
                buffer[i] = 0
                try closure(buffer)
            })
        }
    }
}

// MARK: Write
extension PostgresQueryMessage {
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
    public static func query(_ sql: String) -> PostgresQueryMessage {
        return PostgresQueryMessage(sql)
    }
}