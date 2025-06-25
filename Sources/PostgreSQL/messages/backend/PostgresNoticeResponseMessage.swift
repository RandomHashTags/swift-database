
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-NOTICERESPONSE
public struct PostgresNoticeResponseMessage: PostgresNoticeResponseMessageProtocol {
    public let fields:[String] // TODO: support binary format

    @inlinable
    public init(fields: [String]) {
        self.fields = fields
    }
}

// MARK: Parse
extension PostgresNoticeResponseMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage
    ) throws -> Self {
        guard message.type == .N else {
            throw PostgresError.noticeResponse("message type != .N")
        }
        var fields = [String]()
        let length:Int32 = message.bodyCount
        var startIndex = 0
        while startIndex < length {
            let code:UInt8 = message.body.loadUnalignedInt(offset: startIndex)
            startIndex += 1
            if code == 0 {
                break
            } else {
                guard let (string, length) = message.body.loadNullTerminatedStringBigEndian(offset: startIndex) else {
                    throw PostgresError.noticeResponse("failed to load string from message body after index \(startIndex)")
                }
                fields.append(string)
                startIndex += length
            }
        }
        return .init(fields: fields)
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func noticeResponse(logger: Logger) throws -> PostgresNoticeResponseMessage {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresNoticeResponseMessage")
        #endif
        return try PostgresNoticeResponseMessage.parse(message: self)
    }
}