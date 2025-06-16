
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-FUNCTIONCALL
public struct PostgresFunctionCallMessage: PostgresFunctionCallMessageProtocol {
    public var objectID:Int32
    public var argumentFormatCodes:[Int16]
    public var arguments:[String?] // TODO: support binary format
    public var formatCode:Int16

    @inlinable
    public init(
        objectID: Int32,
        argumentFormatCodes: [Int16],
        arguments: [String?],
        formatCode: Int16
    ) { // TODO: finish
        self.objectID = objectID
        self.argumentFormatCodes = argumentFormatCodes
        self.arguments = arguments
        self.formatCode = formatCode
    }
}

// MARK: Payload
extension PostgresFunctionCallMessage {
    @inlinable
    public mutating func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        // TODO: implement
    }
}

// MARK: Write
extension PostgresFunctionCallMessage {
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