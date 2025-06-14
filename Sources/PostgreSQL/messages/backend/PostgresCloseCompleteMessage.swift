
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