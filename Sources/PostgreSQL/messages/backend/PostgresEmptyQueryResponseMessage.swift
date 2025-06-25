
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
        message: PostgresRawMessage
    ) throws -> Self {
        guard message.type == .I else {
            throw PostgresError.emptyQueryResponse("message type != .I")
        }
        return .init()
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func emptyQueryResponse(logger: Logger) throws -> PostgresEmptyQueryResponseMessage {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresEmptyQueryResponseMessage")
        #endif
        return try PostgresEmptyQueryResponseMessage.parse(message: self)
    }
}