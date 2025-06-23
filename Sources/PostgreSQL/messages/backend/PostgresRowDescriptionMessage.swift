
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
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .T else {
            throw PostgresError.rowDescription("message type != .T")
        }
        let numberOfColumns:Int16 = message.body.loadUnalignedIntBigEndian(offset: 4)
        var columns = [Column]()
        columns.reserveCapacity(Int(numberOfColumns))
        var i = 0
        var offset = 6
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
        try closure(.init(columns: columns))
    }
}

// MARK: Convenience
extension PostgresRowDescriptionMessage {
    @inlinable
    public func decode<T: PostgresDataRowDecodable>(
        on connection: inout PostgresConnection,
        as decodable: T.Type
    ) throws -> [T?] {
        let logger = connection.logger
        var values = [T?]()
        try connection.waitUntilReadyForQuery { msg in
            try PostgresConnection.QueryMessage.ConcreteResponse.parse(logger: logger, msg: msg) { response in
                switch response {
                case .dataRow(let dataRow):
                    values.append(try dataRow.decode(as: decodable))
                case .readyForQuery:
                    break
                default:
                    break
                }
            }
        }
        return values
    }
}

extension PostgresRawMessage {
    @inlinable
    public func rowDescription(logger: Logger, _ closure: (consuming PostgresRowDescriptionMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresRowDescriptionMessage")
        #endif
        try PostgresRowDescriptionMessage.parse(message: self, closure)
    }
}