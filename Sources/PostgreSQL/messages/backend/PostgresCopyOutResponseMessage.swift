
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-COPYOUTRESPONSE
public struct PostgresCopyOutResponseMessage: PostgresCopyOutResponseMessageProtocol {
    public var format:Int8
    public var columnFormatCodes:[Int16]

    @inlinable
    public init(format: Int8, columnFormatCodes: [Int16]) {
        self.format = format
        self.columnFormatCodes = columnFormatCodes
    }
}

// MARK: Parse
extension PostgresCopyOutResponseMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .H else {
            throw PostgresError.copyOutResponse("message type != .H")
        }
        let format:Int8 = message.body.loadUnalignedIntBigEndian(offset: 4)
        let numberOfColumns:Int16 = message.body.loadUnalignedIntBigEndian(offset: 5)
        var columnFormatCodes:[Int16] = []
        if numberOfColumns > 0 {
            columnFormatCodes.reserveCapacity(Int(numberOfColumns))
            var offset = 7
            for _ in 0..<numberOfColumns {
                columnFormatCodes.append(message.body.loadUnalignedIntBigEndian(offset: offset))
                offset += 2
            }
        }
        try closure(.init(format: format, columnFormatCodes: columnFormatCodes))
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func copyOutResponse(logger: Logger, _ closure: (consuming PostgresCopyOutResponseMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresCopyOutResponseMessage")
        #endif
        try PostgresCopyOutResponseMessage.parse(message: self, closure)
    }
}