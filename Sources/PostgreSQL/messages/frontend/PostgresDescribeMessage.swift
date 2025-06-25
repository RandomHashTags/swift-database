
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-DESCRIBE
public struct PostgresDescribeMessage: PostgresDescribeMessageProtocol {
    public var type:DescribeType

    @inlinable
    public init(type: DescribeType) {
        self.type = type
    }
}

// MARK: DescribeType
extension PostgresDescribeMessage {
    public enum DescribeType: Sendable {
        case preparedStatement(name: String)
        case portal(name: String)

        @inlinable
        public var byte: UInt8 {
            switch self {
            case .preparedStatement: .S
            case .portal: .P
            }
        }
    }
}

// MARK: Payload
extension PostgresDescribeMessage {
    @inlinable
    public mutating func payload() -> ByteBuffer {
        switch type {
        case .preparedStatement(var name), .portal(var name):
            return name.withUTF8 { nameBuffer in
                let capacity = 7 + nameBuffer.count
                let buffer = ByteBuffer(capacity: capacity)
                var i = 0
                buffer.writePostgresMessageHeader(type: .D, capacity: capacity, to: &i)
                buffer[i] = type.byte
                i += 1
                buffer.copyBuffer(nameBuffer, to: &i)
                buffer[i] = 0
                return buffer
            }
        }
    }
}

// MARK: Write
extension PostgresDescribeMessage {
    @inlinable
    public mutating func write<Connection: PostgresConnectionProtocol & ~Copyable>(
        to connection: borrowing Connection
    ) async throws {
        try await connection.writeBuffer(payload())
    }
}

// MARK: Describe
extension PostgresRawMessage {
    @inlinable
    public static func describe(type: PostgresDescribeMessage.DescribeType) -> PostgresDescribeMessage {
        return PostgresDescribeMessage(type: type)
    }
}