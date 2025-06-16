
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-PORTALSUSPENDED
public struct PostgresPortalSuspendedMessage: PostgresPortalSuspendedMessageProtocol {
    @inlinable
    public init() {
    }
}

// MARK: Parse
extension PostgresPortalSuspendedMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .s else {
            throw PostgresError.portalSuspended("message type != .s")
        }
        try closure(.init())
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func portalSuspend(logger: Logger, _ closure: (consuming PostgresPortalSuspendedMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresPortalSuspendedMessage")
        #endif
        try PostgresPortalSuspendedMessage.parse(message: self, closure)
    }
}