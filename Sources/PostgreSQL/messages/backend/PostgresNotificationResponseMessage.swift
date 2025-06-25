
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-NOTIFICATIONRESPONSE
public struct PostgresNotificationResponseMessage: PostgresNoDataMessageProtocol {
    public var processID:Int32
    public var channel:String
    public var payload:String

    @inlinable
    public init(
        processID: Int32,
        channel: String,
        payload: String
    ) {
        self.processID = processID
        self.channel = channel
        self.payload = payload
    }
}

// MARK: Parse
extension PostgresNotificationResponseMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage
    ) throws -> Self {
        guard message.type == .A else {
            throw PostgresError.notificationResponse("message type != .A")
        }
        let processID:Int32 = message.body.loadUnalignedInt()
        var offset = 4
        guard let (channel, channelLength) = message.body.loadNullTerminatedStringBigEndian(offset: offset) else {
            throw PostgresError.notificationResponse("failed to load channel string from message body after index \(offset)")
        }
        offset += channelLength
        guard let (payload, _) = message.body.loadNullTerminatedStringBigEndian(offset: offset) else {
            throw PostgresError.notificationResponse("failed to load payload string from message body after index \(offset)")
        }
        return .init(processID: processID, channel: channel, payload: payload)
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func notificationResponse(logger: Logger) throws -> PostgresNotificationResponseMessage {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresNotificationResponseMessage")
        #endif
        return try PostgresNotificationResponseMessage.parse(message: self)
    }
}