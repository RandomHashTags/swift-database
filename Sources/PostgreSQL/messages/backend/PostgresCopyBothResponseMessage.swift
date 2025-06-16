
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-COPYBOTHRESPONSE
public struct PostgresCopyBothResponseMessage: PostgresCopyBothResponseMessageProtocol {
    public var format:Int8
    public var columnFormatCodes:[Int16]

    @inlinable
    public init(format: Int8, columnFormatCodes: [Int16]) {
        self.format = format
        self.columnFormatCodes = columnFormatCodes
    }
}

// MARK: Parse
extension PostgresCopyBothResponseMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .W else {
            throw PostgresError.copyBothResponse("message type != .W")
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
    public func copyBothResponse(logger: Logger, _ closure: (consuming PostgresCopyBothResponseMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresCopyBothResponseMessage")
        #endif
        try PostgresCopyBothResponseMessage.parse(message: self, closure)
    }
}