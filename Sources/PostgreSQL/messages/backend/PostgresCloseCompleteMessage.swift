
import Logging
import PostgreSQLBlueprint

extension PostgresRawMessage {
    /// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-CLOSECOMPLETE
    public struct CloseComplete: PostgresCloseCompleteMessageProtocol {
        public init() {
        }
    }
}

// MARK: Parse
extension PostgresRawMessage.CloseComplete {
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
    public func closeComplete(logger: Logger, _ closure: (consuming CloseComplete) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as CloseComplete")
        #endif
        try CloseComplete.parse(message: self, closure)
    }
}