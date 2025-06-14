
import Logging
import PostgreSQLBlueprint

extension PostgresRawMessage {
    /// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-BACKENDKEYDATA
    public struct BackendKeyData: PostgresBackendKeyDataMessageProtocol {
        public let processID:Int32
        public let secretKey:Int32

        public init(processID: Int32, secretKey: Int32) {
            self.processID = processID
            self.secretKey = secretKey
        }
    }
}

// MARK: Parse
extension PostgresRawMessage.BackendKeyData {
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .K else {
            throw PostgresError.backendKeyData("message type != .K")
        }
        let processID:Int32 = message.body.loadUnalignedIntBigEndian(offset: 4)
        let secretKey:Int32 = message.body.loadUnalignedIntBigEndian(offset: 8)
        try closure(.init(processID: processID, secretKey: secretKey))
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func backendKeyData(logger: Logger, _ closure: (consuming BackendKeyData) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as BackendKeyData")
        #endif
        try BackendKeyData.parse(message: self, closure)
    }
}