
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
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .A else {
            throw PostgresError.notificationResponse("message type != .A")
        }
        let processID:Int32 = message.body.loadUnalignedInt(offset: 4)
        var offset = 8
        guard let (channel, channelLength) = message.body.loadNullTerminatedStringBigEndian(offset: offset) else {
            throw PostgresError.notificationResponse("failed to load channel string from message body after index \(offset)")
        }
        offset += channelLength
        guard let (payload, _) = message.body.loadNullTerminatedStringBigEndian(offset: offset) else {
            throw PostgresError.notificationResponse("failed to load payload string from message body after index \(offset)")
        }
        try closure(.init(processID: processID, channel: channel, payload: payload))
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func notificationResponse(logger: Logger, _ closure: (consuming PostgresNotificationResponseMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresNotificationResponseMessage")
        #endif
        try PostgresNotificationResponseMessage.parse(message: self, closure)
    }
}