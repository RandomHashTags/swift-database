
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
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .n else {
            throw PostgresError.noData("message type != .n")
        }
        try closure(.init())
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func noData(logger: Logger, _ closure: (consuming PostgresNoDataMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresNoDataMessage")
        #endif
        try PostgresNoDataMessage.parse(message: self, closure)
    }
}