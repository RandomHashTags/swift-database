
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-EXECUTE
public struct PostgresExecuteMessage: PostgresExecuteMessageProtocol {
    public var name:String
    public var maximumReturnedRows:Int32

    public init(
        name: String,
        maximumReturnedRows: Int32
    ) {
        self.name = name
        self.maximumReturnedRows = maximumReturnedRows
    }
}

// MARK: Payload
extension PostgresExecuteMessage {
    @inlinable
    public mutating func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        try name.withUTF8 { nameBuffer in
            let capacity = 10 + nameBuffer.count
            try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity, { buffer in
                var i = 0
                buffer.writePostgresMessageHeader(type: .E, capacity: capacity, to: &i)
                buffer.copyBuffer(nameBuffer, to: &i)
                buffer[i] = 0
                i += 1
                buffer.writeIntBigEndian(maximumReturnedRows, to: &i)
                try closure(buffer)
            })
        }
    }
}

// MARK: Write
extension PostgresExecuteMessage {
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
    public static func execute(name: String, maximumReturnedRows: Int32) -> PostgresExecuteMessage {
        return PostgresExecuteMessage(name: name, maximumReturnedRows: maximumReturnedRows)
    }
}