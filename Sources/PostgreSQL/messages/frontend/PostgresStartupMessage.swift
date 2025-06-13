
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

extension PostgresRawMessage {
    /// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-STARTUPMESSAGE
    public struct StartupMessage: PostgresStartupMessageProtocol {
        public var protocolVersion:Int32
        public var parameters:[String:String]

        public init(
            protocolVersion: Int32 = 196608, // protocol version 3.0 (0x00030000 = 196608)
            parameters: [String:String]
        ) {
            self.protocolVersion = protocolVersion
            self.parameters = parameters
        }
    }
}

// MARK: Payload
extension PostgresRawMessage.StartupMessage {
    @inlinable
    public mutating func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        try Self.createBody(parameters: parameters) { bodyBuffer in
            let capacity = 8 + bodyBuffer.count
            try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity, { buffer in
                var i = 0
                buffer.writeIntBigEndian(Int32(capacity), to: &i)
                buffer.writeIntBigEndian(protocolVersion, to: &i)
                buffer.copyBuffer(bodyBuffer, to: &i)
                try closure(buffer)
            })
        }
    }

    @inlinable
    static func createBody(
        parameters: [String:String],
        _ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void
    ) rethrows {
        var capacity = 0
        for (key, value) in parameters {
            capacity += key.count + value.count + 2
        }
        try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity, { buffer in
            var i = 0
            for (var key, var value) in parameters {
                key.withUTF8 { keyBuffer in
                    buffer.copyBuffer(keyBuffer, to: &i)
                    buffer[i] = 0
                    i += 1
                }
                value.withUTF8 { valueBuffer in
                    buffer.copyBuffer(valueBuffer, to: &i)
                    buffer[i] = 0
                    i += 1
                }
            }
            try closure(buffer)
        })
    }
}

// MARK: Write
extension PostgresRawMessage.StartupMessage {
    @inlinable
    public mutating func write<Connection: PostgresConnectionProtocol & ~Copyable>(to connection: borrowing Connection) throws {
        try payload {
            try connection.writeBuffer($0.baseAddress!, length: $0.count)
        }
    }
}