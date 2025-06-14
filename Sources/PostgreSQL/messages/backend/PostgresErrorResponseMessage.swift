
import PostgreSQLBlueprint

extension PostgresRawMessage {
    /// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-ERRORRESPONSE
    public struct ErrorResponse: PostgresBackendKeyDataMessageProtocol {
        public var type:UInt8
        public var value:String?

        public init(type: UInt8, value: String?) {
            self.type = type
            self.value = value
        }
    }
}

// MARK: Parse
extension PostgresRawMessage.ErrorResponse {
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .E else {
            throw PostgresError.errorResponse("message type != .E")
        }
        let type:UInt8 = message.body.loadUnalignedIntBigEndian(offset: 4)
        var value:String?
        if type == 0 {
            value = nil
        } else {
            value = message.body.loadNullTerminatedString(offset: 5)
        }
        try closure(.init(type: type, value: value))
    }
}