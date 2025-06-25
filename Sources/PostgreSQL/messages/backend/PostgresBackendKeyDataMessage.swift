
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-BACKENDKEYDATA
public struct PostgresBackendKeyDataMessage: PostgresBackendKeyDataMessageProtocol {
    public let processID:Int32
    public let secretKey:Int32

    @inlinable
    public init(processID: Int32, secretKey: Int32) {
        self.processID = processID
        self.secretKey = secretKey
    }
}

// MARK: Parse
extension PostgresBackendKeyDataMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage
    ) throws -> Self {
        guard message.type == .K else {
            throw PostgresError.backendKeyData("message type != .K")
        }
        let processID:Int32 = message.body.loadUnalignedIntBigEndian()
        let secretKey:Int32 = message.body.loadUnalignedIntBigEndian(offset: 4)
        return .init(processID: processID, secretKey: secretKey)
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func backendKeyData(logger: Logger) throws -> PostgresBackendKeyDataMessage {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresBackendKeyDataMessage")
        #endif
        return try PostgresBackendKeyDataMessage.parse(message: self)
    }
}