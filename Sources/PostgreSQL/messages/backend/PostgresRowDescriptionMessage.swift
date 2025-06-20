
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-ROWDESCRIPTION
public struct PostgresRowDescriptionMessage: PostgresRowDescriptionMessageProtocol {
    public var fields:[Field]

    @inlinable
    public init(fields: [Field]) {
        self.fields = fields
    }
}

// MARK: Field
extension PostgresRowDescriptionMessage {
    public struct Field: Sendable {
        public var name:String
        public var tableObjectID:Int32
        public var columnAttributeNumber:Int32
        public var dataTypeObjectID:Int32
        public var dataTypeSize:Int16
        public var typeModifier:Int32
        public var formatCode:Int16

        @inlinable
        public init(
            name: String,
            tableObjectID: Int32,
            columnAttributeNumber: Int32,
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
        let numberOfFields:Int16 = message.body.loadUnalignedIntBigEndian(offset: 4)
        var fields = [Field]()
        fields.reserveCapacity(Int(numberOfFields))
        var i = 0
        var offset = 6
        while i < numberOfFields {
            guard let (name, nameLength) = message.body.loadNullTerminatedStringBigEndian(offset: offset) else {
                throw PostgresError.parameterStatus("failed to load field name string from message body after index \(offset)")
            }
            offset += nameLength
            let tableObjectID:Int32 = message.body.loadUnalignedIntBigEndian(offset: offset)
            offset += 4
            let columnAttributeNumber:Int32 = message.body.loadUnalignedIntBigEndian(offset: offset)
            offset += 4
            let dataTypeObjectID:Int32 = message.body.loadUnalignedIntBigEndian(offset: offset)
            offset += 4
            let dataTypeSize:Int16 = message.body.loadUnalignedIntBigEndian(offset: offset)
            offset += 2
            let typeModifier:Int32 = message.body.loadUnalignedIntBigEndian(offset: offset)
            offset += 4
            let formatCode:Int16 = message.body.loadUnalignedIntBigEndian(offset: offset)
            offset += 2
            fields.append(.init(
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
        try closure(.init(fields: fields))
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func rowDescription(logger: Logger, _ closure: (consuming PostgresRowDescriptionMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresRowDescriptionMessage")
        #endif
        try PostgresRowDescriptionMessage.parse(message: self, closure)
    }
}