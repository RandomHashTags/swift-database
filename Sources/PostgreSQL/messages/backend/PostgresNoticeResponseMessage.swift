
import Logging
import PostgreSQLBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-NOTICERESPONSE
public struct PostgresNoticeResponseMessage: PostgresNoticeResponseMessageProtocol {
    public let fields:[String] // TODO: support binary format

    public init(fields: [String]) {
        self.fields = fields
    }
}

// MARK: Parse
extension PostgresNoticeResponseMessage {
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .N else {
            throw PostgresError.noticeResponse("message type != .N")
        }
        var fields = [String]()
        let length:Int32 = message.body.loadUnalignedIntBigEndian()
        var startIndex = 4
        while startIndex < length {
            let code:UInt8 = message.body.loadUnalignedInt(offset: startIndex)
            if code == 0 {
                break
            } else {
                startIndex += 1
                let field = message.body.loadNullTerminatedString(offset: startIndex)
                startIndex += field.utf8.count
                fields.append(field)
            }
        }
        try closure(.init(fields: fields))
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func noticeResponse(logger: Logger, _ closure: (consuming PostgresNoticeResponseMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresNoticeResponseMessage")
        #endif
        try PostgresNoticeResponseMessage.parse(message: self, closure)
    }
}