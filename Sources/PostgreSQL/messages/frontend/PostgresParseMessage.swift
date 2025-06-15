
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-PARSE
public struct PostgresParseMessage<
        let parameterDataTypeObjectIDsCount: Int
    >: PostgresParseMessageProtocol {
    public var destinationName:String
    public var query:String
    public var parameterDataTypes:Int16
    public var parameterDataTypeObjectIDs:InlineArray<parameterDataTypeObjectIDsCount, Int32>

    public init(
        destinationName: String,
        query: String,
        parameterDataTypes: Int16,
        parameterDataTypeObjectIDs: InlineArray<parameterDataTypeObjectIDsCount, Int32>
    ) {
        self.destinationName = destinationName
        self.query = query
        self.parameterDataTypes = parameterDataTypes
        self.parameterDataTypeObjectIDs = parameterDataTypeObjectIDs
    }
}

// MARK: Payload
extension PostgresParseMessage {
    @inlinable
    public mutating func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        try destinationName.withUTF8 { destinationNameBuffer in
            try query.withUTF8 { queryBuffer in
                let capacity = 7 + destinationNameBuffer.count + queryBuffer.count + 2 + (parameterDataTypeObjectIDs.count * 4)
                try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity, { buffer in
                    var i = 0
                    buffer.writePostgresMessageHeader(type: .P, capacity: capacity, to: &i)
                    buffer.copyBuffer(destinationNameBuffer, to: &i)
                    buffer[i] = 0
                    i += 1
                    buffer.copyBuffer(queryBuffer, to: &i)
                    buffer[i] = 0
                    i += 1
                    buffer.writeIntBigEndian(parameterDataTypes, to: &i)
                    for indice in parameterDataTypeObjectIDs.indices {
                        buffer.writeIntBigEndian(parameterDataTypeObjectIDs[indice], to: &i)
                    }
                    try closure(buffer)
                })
            }
        }
    }
}

// MARK: Write
extension PostgresParseMessage {
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
    public static func parse<let parameterDataTypeObjectIDsCount: Int>(
        destinationName: String,
        query: String,
        parameterDataTypes: Int16,
        parameterDataTypeObjectIDs: InlineArray<parameterDataTypeObjectIDsCount, Int32>
    ) -> PostgresParseMessage<parameterDataTypeObjectIDsCount> {
        return PostgresParseMessage(destinationName: destinationName, query: query, parameterDataTypes: parameterDataTypes, parameterDataTypeObjectIDs: parameterDataTypeObjectIDs)
    }
}