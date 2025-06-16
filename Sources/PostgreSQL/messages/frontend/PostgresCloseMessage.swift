
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-CLOSE
public struct PostgresCloseMessage: PostgresCloseMessageProtocol {
    public var type:CloseType

    @inlinable
    public init(type: CloseType) {
        self.type = type
    }
}

// MARK: CloseType
extension PostgresCloseMessage {
    public enum CloseType: Sendable {
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
extension PostgresCloseMessage {
    @inlinable
    public mutating func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        switch type {
        case .preparedStatement(var name), .portal(name: var name):
            try name.withUTF8 { nameBuffer in
                let capacity = 6 + nameBuffer.count + 1
                try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity, { buffer in
                    var i = 0
                    buffer.writePostgresMessageHeader(type: .C, capacity: capacity, to: &i)
                    buffer[i] = type.byte
                    i += 1
                    buffer.copyBuffer(nameBuffer, to: &i)
                    buffer[i] = 0
                    try closure(buffer)
                })
            }
        }
    }
}

// MARK: Write
extension PostgresCloseMessage {
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
    public static func close(type: PostgresCloseMessage.CloseType) -> PostgresCloseMessage {
        return PostgresCloseMessage(type: type)
    }
}