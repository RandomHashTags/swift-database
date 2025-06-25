
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

    @inlinable
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
    public mutating func payload() -> ByteBuffer {
        return destinationName.withUTF8 { destinationNameBuffer in
            return query.withUTF8 { queryBuffer in
                let capacity = 7 + destinationNameBuffer.count + queryBuffer.count + 2 + (parameterDataTypeObjectIDs.count * 4)
                let buffer = ByteBuffer(capacity: capacity)
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
                return buffer
            }
        }
    }
}

// MARK: Write
extension PostgresParseMessage {
    @inlinable
    public mutating func write<Connection: PostgresConnectionProtocol & ~Copyable>(
        to connection: borrowing Connection
    ) async throws {
        try await connection.writeBuffer(payload())
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