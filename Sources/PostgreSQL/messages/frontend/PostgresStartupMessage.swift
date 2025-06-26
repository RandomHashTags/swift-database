
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-STARTUPMESSAGE
public struct PostgresStartupMessage: PostgresStartupMessageProtocol {
    public var protocolVersion:Int32
    public var parameters:[String:String]

    @inlinable
    public init(
        protocolVersion: Int32 = 196608, // protocol version 3.0 (0x00030000 = 196608)
        parameters: [String:String]
    ) {
        self.protocolVersion = protocolVersion
        self.parameters = parameters
    }
}

// MARK: Payload
extension PostgresStartupMessage {
    @inlinable
    public mutating func payload() -> ByteBuffer {
        let bodyBuffer = Self.createBody(parameters: parameters)
        let capacity = 8 + bodyBuffer.count
        let buffer = ByteBuffer(capacity: capacity)
        var i = 0
        buffer.writeIntBigEndian(Int32(capacity), to: &i)
        buffer.writeIntBigEndian(protocolVersion, to: &i)
        buffer.copyBuffer(bodyBuffer.baseAddress!, count: bodyBuffer.count, to: &i)
        return buffer
    }

    @inlinable
    static func createBody(
        parameters: [String:String]
    ) -> ByteBuffer {
        var capacity = 1
        for (key, value) in parameters {
            capacity += key.utf8.count + value.utf8.count + 2
        }
        let buffer = ByteBuffer(capacity: capacity)
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
        buffer[i] = 0
        return buffer
    }
}

// MARK: Write
extension PostgresStartupMessage {
    @inlinable
    public mutating func write<Connection: PostgresConnectionProtocol & ~Copyable>(
        to connection: borrowing Connection
    ) async throws {
        try await connection.writeBuffer(payload())
    }
}