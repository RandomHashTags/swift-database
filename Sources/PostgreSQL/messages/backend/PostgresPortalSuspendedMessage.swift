
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
        message: PostgresRawMessage
    ) throws -> Self {
        guard message.type == .s else {
            throw PostgresError.portalSuspended("message type != .s")
        }
        return .init()
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func portalSuspend(logger: Logger) throws -> PostgresPortalSuspendedMessage {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresPortalSuspendedMessage")
        #endif
        return try PostgresPortalSuspendedMessage.parse(message: self)
    }
}