
import Logging
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-ROWDESCRIPTION
public struct PostgresRowDescriptionMessage: PostgresRowDescriptionMessageProtocol {
    public var columns:[Column]

    @inlinable
    public init(columns: [Column]) {
        self.columns = columns
    }
}

// MARK: Column
extension PostgresRowDescriptionMessage {
    public struct Column: Sendable {
        public var name:String
        public var tableObjectID:Int32
        public var columnAttributeNumber:Int16
        public var dataTypeObjectID:Int32
        public var dataTypeSize:Int16
        public var typeModifier:Int32
        public var formatCode:Int16

        @inlinable
        public init(
            name: String,
            tableObjectID: Int32,
            columnAttributeNumber: Int16,
            dataTypeObjectID: Int32,
            dataTypeSize: Int16,
            typeModifier: Int32,
            formatCode: Int16
        ) {
            self.name = name
            self.tableObjectID = tableObjectID
            self.columnAttributeNumber = columnAttributeNumber
            self.dataTypeObjectID = dataTypeObjectID
            self.dataTypeSize = dataTypeSize
            self.typeModifier = typeModifier
            self.formatCode = formatCode
        }
    }
}

// MARK: Parse
extension PostgresRowDescriptionMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage
    ) throws -> Self {
        guard message.type == .T else {
            throw PostgresError.rowDescription("message type != .T")
        }
        let numberOfColumns:Int16 = message.body.loadUnalignedIntBigEndian()
        var columns = [Column]()
        columns.reserveCapacity(Int(numberOfColumns))
        var i = 0
        var offset = 2
        while i < numberOfColumns {
            guard let (name, nameLength) = message.body.loadNullTerminatedStringBigEndian(offset: offset) else {
                throw PostgresError.rowDescription("failed to load column name string from message body after index \(offset)")
            }
            offset += nameLength
            let tableObjectID:Int32 = message.body.loadUnalignedIntBigEndian(offset: offset)
            offset += 4
            let columnAttributeNumber:Int16 = message.body.loadUnalignedIntBigEndian(offset: offset)
            offset += 2
            let dataTypeObjectID:Int32 = message.body.loadUnalignedIntBigEndian(offset: offset)
            offset += 4
            let dataTypeSize:Int16 = message.body.loadUnalignedIntBigEndian(offset: offset)
            offset += 2
            let typeModifier:Int32 = message.body.loadUnalignedIntBigEndian(offset: offset)
            offset += 4
            let formatCode:Int16 = message.body.loadUnalignedIntBigEndian(offset: offset)
            offset += 2
            columns.append(.init(
                name: name,
                tableObjectID: tableObjectID,
                columnAttributeNumber: columnAttributeNumber,
                dataTypeObjectID: dataTypeObjectID,
                dataTypeSize: dataTypeSize,
                typeModifier: typeModifier,
                formatCode: formatCode
            ))
            i += 1
        }
        return .init(columns: columns)
    }
}

// MARK: Decode
extension PostgresRowDescriptionMessage {
    @inlinable
    public func decode<T: PostgresDataRowDecodable, Connection: PostgresConnectionProtocol & ~Copyable>(
        on connection: inout Connection,
        as decodable: T.Type
    ) async throws -> [T?] {
        let logger = connection.logger
        var values = [T?]()
        try await connection.waitUntilReadyForQuery { msg in
            let response = try PostgresConnection.QueryMessage.ConcreteResponse.parse(logger: logger, msg: msg)
            switch response {
            case .dataRow(let dataRow):
                values.append(try dataRow.decode(as: decodable))
            default:
                break
            }
        }
        return values
    }

    @inlinable
    public func decode<T: PostgresDataRowDecodable, Connection: PostgresConnectionProtocol & ~Copyable, let count: Int>(
        on connection: inout Connection,
        as decodable: T.Type
    ) async throws -> InlineArray<count, T?> {
        let logger = connection.logger
        var values = InlineArray<count, T?>(repeating: nil)
        var i = 0
        try await connection.waitUntilReadyForQuery { msg in
            let response = try PostgresConnection.QueryMessage.ConcreteResponse.parse(logger: logger, msg: msg)
            switch response {
            case .dataRow(let dataRow):
                values[i] = try dataRow.decode(as: decodable)
                i += 1
            default:
                break
            }
        }
        return values
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func rowDescription(logger: Logger) throws -> PostgresRowDescriptionMessage {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresRowDescriptionMessage")
        #endif
        return try PostgresRowDescriptionMessage.parse(message: self)
    }
}