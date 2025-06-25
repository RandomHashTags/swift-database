
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-COMMANDCOMPLETE
public struct PostgresCommandCompleteMessage: PostgresCommandCompleteMessageProtocol {
    public var commandTag:String

    @inlinable
    public init(commandTag: String) {
        self.commandTag = commandTag
    }
}

// MARK: Parse
extension PostgresCommandCompleteMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage
    ) throws -> Self {
        guard message.type == .C else {
            throw PostgresError.commandComplete("message type != .C")
        }
        return .init(commandTag: message.body.loadStringBigEndian(offset: 0, count: Int(message.bodyCount)))
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func commandComplete(logger: Logger) throws -> PostgresCommandCompleteMessage {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresCommandCompleteMessage")
        #endif
        return try PostgresCommandCompleteMessage.parse(message: self)
    }
}