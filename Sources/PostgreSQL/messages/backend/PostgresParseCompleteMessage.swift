
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
        message: PostgresRawMessage
    ) throws -> Self {
        guard message.type == .`1` else {
            throw PostgresError.parseComplete("message type != .`1`")
        }
        return .init()
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func parseComplete(logger: Logger) throws -> PostgresParseCompleteMessage {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresParseCompleteMessage")
        #endif
        return try PostgresParseCompleteMessage.parse(message: self)
    }
}