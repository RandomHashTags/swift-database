
import Logging
import PostgreSQLBlueprint

extension PostgresRawMessage {
    /// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-COMMANDCOMPLETE
    public struct CommandComplete: PostgresCommandCompleteMessageProtocol {
        public var commandTag:String

        public init(commandTag: String) {
            self.commandTag = commandTag
        }
    }
}

// MARK: Parse
extension PostgresRawMessage.CommandComplete {
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .C else {
            throw PostgresError.commandComplete("message type != .C")
        }
        try closure(.init(commandTag: message.body.loadNullTerminatedString()))
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func commandComplete(logger: Logger, _ closure: (consuming CommandComplete) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as CommandComplete")
        #endif
        try CommandComplete.parse(message: self, closure)
    }
}