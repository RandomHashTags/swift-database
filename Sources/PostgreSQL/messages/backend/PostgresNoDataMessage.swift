
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-NODATA
public struct PostgresNoDataMessage: PostgresNoDataMessageProtocol {
    @inlinable
    public init() {
    }
}

// MARK: Parse
extension PostgresNoDataMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage
    ) throws -> Self {
        guard message.type == .n else {
            throw PostgresError.noData("message type != .n")
        }
        return .init()
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func noData(logger: Logger) throws -> PostgresNoDataMessage {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresNoDataMessage")
        #endif
        return try PostgresNoDataMessage.parse(message: self)
    }
}