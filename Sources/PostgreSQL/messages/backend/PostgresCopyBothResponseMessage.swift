
import Logging
import PostgreSQLBlueprint

extension PostgresRawMessage {
    /// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-COPYBOTHRESPONSE
    public struct CopyBothResponse: PostgresCopyBothResponseMessageProtocol {
        public var format:Int8
        public var columnFormatCodes:[Int16]

        public init(format: Int8, columnFormatCodes: [Int16]) {
            self.format = format
            self.columnFormatCodes = columnFormatCodes
        }
    }
}

// MARK: Parse
extension PostgresRawMessage.CopyBothResponse {
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
    public func copyBothResponse(logger: Logger, _ closure: (consuming CopyBothResponse) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as CopyBothResponse")
        #endif
        try CopyBothResponse.parse(message: self, closure)
    }
}