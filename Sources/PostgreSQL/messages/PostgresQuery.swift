
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

extension PostgresMessage {
    public struct Query: PostgresQueryMessageProtocol {
        public var query:String

        public init(_ query: String) {
            self.query = query
        }
    }
}

// MARK: Payload
extension PostgresMessage.Query {
    @inlinable
    public mutating func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        try query.withUTF8 { queryBuffer in
            let capacity = 1 + 4 + queryBuffer.count + 1
            try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity, { buffer in
                buffer[0] = .Q

                var i = 1
                withUnsafeBytes(of: (4 + queryBuffer.count).bigEndian, {
                    $0.forEach {
                        buffer[i] = $0
                        i += 1
                    }
                })
                buffer.copyBuffer(queryBuffer, to: &i)
                buffer[i] = 0
                try closure(buffer)
            })
        }
    }
}

// MARK: Write
extension PostgresMessage.Query {
    @inlinable
    public mutating func write<Connection: PostgresConnectionProtocol & ~Copyable>(to connection: borrowing Connection) throws {
        try payload {
            try connection.writeBuffer($0.baseAddress!, length: $0.count)
        }
    }
}