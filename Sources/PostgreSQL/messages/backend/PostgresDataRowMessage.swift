
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-DATAROW
public struct PostgresDataRowMessage: PostgresDataRowMessageProtocol {
    public var columns:[String?] // TODO: support binary format

    @inlinable
    public init(columns: [String?]) {
        self.columns = columns
    }
}

// MARK: Decode
extension PostgresDataRowMessage {
    @inlinable
    public func decode<T: PostgresDataRowDecodable>(as decodable: T.Type) throws -> T? {
        return try T.postgresDecode(columns: columns)
    }
}

// MARK: Parse
extension PostgresDataRowMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .D else {
            throw PostgresError.dataRow("message type != .D")
        }
        let numberOfColumnValues:Int16 = message.body.loadUnalignedIntBigEndian(offset: 4)
        var columns:[String?] = []
        if numberOfColumnValues > 0 {
            columns.reserveCapacity(Int(numberOfColumnValues))
            var offset = 6
            for _ in 0..<Int(numberOfColumnValues) {
                let lengthOfColumnValue:Int32 = message.body.loadUnalignedIntBigEndian(offset: offset)
                offset += 4
                let result:String?
                if lengthOfColumnValue == -1 {
                    result = nil
                } else {
                    result = message.body.loadStringBigEndian(offset: offset, count: Int(lengthOfColumnValue))
                    offset += Int(lengthOfColumnValue)
                }
                columns.append(result)
            }
        }
        try closure(.init(columns: columns))
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func dataRow(logger: Logger, _ closure: (consuming PostgresDataRowMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresDataRowMessage")
        #endif
        try PostgresDataRowMessage.parse(message: self, closure)
    }
}