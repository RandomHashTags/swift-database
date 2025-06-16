
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-EMPTYQUERYRESPONSE
public struct PostgresEmptyQueryResponseMessage: PostgresEmptyQueryResponseMessageProtocol {
    @inlinable
    public init() {
    }
}

// MARK: Parse
extension PostgresEmptyQueryResponseMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .I else {
            throw PostgresError.emptyQueryResponse("message type != .I")
        }
        try closure(.init())
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func emptyQueryResponse(logger: Logger, _ closure: (consuming PostgresEmptyQueryResponseMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresEmptyQueryResponseMessage")
        #endif
        try PostgresEmptyQueryResponseMessage.parse(message: self, closure)
    }
}