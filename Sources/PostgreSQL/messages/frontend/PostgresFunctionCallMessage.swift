
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

extension PostgresRawMessage {
    /// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-FUNCTIONCALL
    public struct FunctionCall: PostgresFunctionCallMessageProtocol {
        public var objectID:Int32

        public init(
            objectID: Int32
        ) { // TODO: finish
            self.objectID = objectID
        }
    }
}

// MARK: Payload
extension PostgresRawMessage.FunctionCall {
    @inlinable
    public mutating func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        // TODO: implement
    }
}

// MARK: Write
extension PostgresRawMessage.FunctionCall {
    @inlinable
    public mutating func write<Connection: PostgresConnectionProtocol & ~Copyable>(to connection: borrowing Connection) throws {
        try payload {
            try connection.writeBuffer($0.baseAddress!, length: $0.count)
        }
    }
}

// MARK: Convenience
extension PostgresRawMessage {
}