
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-PARAMETERSTATUS
public struct PostgresParameterStatusMessage: PostgresParameterStatusMessageProtocol {
    public var parameter:String
    public var value:String

    @inlinable
    public init(parameter: String, value: String) {
        self.parameter = parameter
        self.value = value
    }
}

// MARK: Parse
extension PostgresParameterStatusMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .S else {
            throw PostgresError.parameterDescription("message type != .S")
        }
        guard let (parameter, parameterLength) = message.body.loadNullTerminatedStringBigEndian(offset: 4) else {
            throw PostgresError.parameterStatus("failed to load parameter string from message body after index \(4)")
        }
        guard let (value, _) = message.body.loadNullTerminatedStringBigEndian(offset: 4 + parameterLength) else {
            throw PostgresError.parameterStatus("failed to load value string from message body after index \(4 + parameterLength)")
        }
        try closure(.init(parameter: parameter, value: value))
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func parameterStatus(logger: Logger, _ closure: (consuming PostgresParameterStatusMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresParameterStatusMessage")
        #endif
        try PostgresParameterStatusMessage.parse(message: self, closure)
    }
}