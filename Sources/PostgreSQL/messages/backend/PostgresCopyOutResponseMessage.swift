
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
        message: PostgresRawMessage
    ) throws -> Self {
        guard message.type == .H else {
            throw PostgresError.copyOutResponse("message type != .H")
        }
        let format:Int8 = message.body.loadUnalignedIntBigEndian()
        let numberOfColumns:Int16 = message.body.loadUnalignedIntBigEndian(offset: 1)
        var columnFormatCodes:[Int16] = []
        if numberOfColumns > 0 {
            columnFormatCodes.reserveCapacity(Int(numberOfColumns))
            var offset = 3
            for _ in 0..<numberOfColumns {
                columnFormatCodes.append(message.body.loadUnalignedIntBigEndian(offset: offset))
                offset += 2
            }
        }
        return .init(format: format, columnFormatCodes: columnFormatCodes)
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func copyOutResponse(logger: Logger) throws -> PostgresCopyOutResponseMessage {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresCopyOutResponseMessage")
        #endif
        return try PostgresCopyOutResponseMessage.parse(message: self)
    }
}