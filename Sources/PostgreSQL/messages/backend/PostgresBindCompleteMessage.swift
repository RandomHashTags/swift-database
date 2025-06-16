
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-BINDCOMPLETE
public struct PostgresBindCompleteMessage: PostgresBindCompleteMessageProtocol {
    @inlinable
    public init() {
    }
}

// MARK: Parse
extension PostgresBindCompleteMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .`2` else {
            throw PostgresError.bindComplete("message type != .`2`")
        }
        try closure(.init())
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func bindComplete(logger: Logger, _ closure: (consuming PostgresBindCompleteMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresBindCompleteMessage")
        #endif
        try PostgresBindCompleteMessage.parse(message: self, closure)
    }
}