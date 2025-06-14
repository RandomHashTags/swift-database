
import PostgreSQLBlueprint

extension PostgresRawMessage {
    /// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-BINDCOMPLETE
    public struct BindComplete: PostgresBindCompleteMessageProtocol {
        public init() {
        }
    }
}

// MARK: Parse
extension PostgresRawMessage.BindComplete {
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