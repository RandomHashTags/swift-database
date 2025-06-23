
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
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .C else {
            throw PostgresError.commandComplete("message type != .C")
        }
        try closure(.init(commandTag: message.body.loadStringBigEndian(offset: 4, count: message.body.count - 4)))
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func commandComplete(logger: Logger, _ closure: (consuming PostgresCommandCompleteMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresCommandCompleteMessage")
        #endif
        try PostgresCommandCompleteMessage.parse(message: self, closure)
    }
}