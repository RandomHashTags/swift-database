
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-CLOSECOMPLETE
public struct PostgresCloseCompleteMessage: PostgresCloseCompleteMessageProtocol {
    @inlinable
    public init() {
    }
}

// MARK: Parse
extension PostgresCloseCompleteMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .`3` else {
            throw PostgresError.closeComplete("message type != .`3`")
        }
        try closure(.init())
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func closeComplete(logger: Logger, _ closure: (consuming PostgresCloseCompleteMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresCloseCompleteMessage")
        #endif
        try PostgresCloseCompleteMessage.parse(message: self, closure)
    }
}