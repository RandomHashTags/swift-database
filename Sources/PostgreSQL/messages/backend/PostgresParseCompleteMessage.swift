
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-PARSECOMPLETE
public struct PostgresParseCompleteMessage: PostgresParseCompleteMessageProtocol {
    @inlinable
    public init() {
    }
}

// MARK: Parse
extension PostgresParseCompleteMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .`1` else {
            throw PostgresError.parseComplete("message type != .`1`")
        }
        try closure(.init())
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func parseComplete(logger: Logger, _ closure: (consuming PostgresParseCompleteMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresParseCompleteMessage")
        #endif
        try PostgresParseCompleteMessage.parse(message: self, closure)
    }
}