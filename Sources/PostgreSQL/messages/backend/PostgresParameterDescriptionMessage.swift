
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-PARAMETERDESCRIPTION
public struct PostgresParameterDescriptionMessage: PostgresParameterDescriptionMessageProtocol {
    public var parameters:[Int32]

    @inlinable
    public init(parameters: [Int32]) {
        self.parameters = parameters
    }
}

// MARK: Parse
extension PostgresParameterDescriptionMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .t else {
            throw PostgresError.parameterDescription("message type != .t")
        }
        let length:Int32 = message.body.loadUnalignedIntBigEndian() - 6
        var parameters = [Int32]()
        let parametersCount:Int16 = message.body.loadUnalignedIntBigEndian(offset: 4)
        parameters.reserveCapacity(Int(parametersCount))
        var offset = 6
        while offset < length {
            parameters.append(message.body.loadUnalignedIntBigEndian(offset: offset))
            offset += 4
        }
        try closure(.init(parameters: parameters))
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func parameterDescription(logger: Logger, _ closure: (consuming PostgresParameterDescriptionMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresParameterDescriptionMessage")
        #endif
        try PostgresParameterDescriptionMessage.parse(message: self, closure)
    }
}