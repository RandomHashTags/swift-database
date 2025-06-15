
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-GSSRESPONSE
public struct PostgresGSSResponseMessage: PostgresGSSResponseMessageProtocol {
    public var data:String // TODO: support binary format

    public init(data: String) {
        self.data = data
    }
}

// MARK: Payload
extension PostgresGSSResponseMessage {
    @inlinable
    public mutating func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        // TODO: implement
    }
}

// MARK: Write
extension PostgresGSSResponseMessage {
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
    public static func gssResponse(data: String) -> PostgresGSSResponseMessage {
        return PostgresGSSResponseMessage(data: data)
    }
}