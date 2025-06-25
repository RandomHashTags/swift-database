
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
        message: PostgresRawMessage
    ) throws -> Self {
        guard message.type == .t else {
            throw PostgresError.parameterDescription("message type != .t")
        }
        let length = message.bodyCount
        var parameters = [Int32]()
        let parametersCount:Int16 = message.body.loadUnalignedIntBigEndian()
        parameters.reserveCapacity(Int(parametersCount))
        var offset = 2
        while offset < length {
            parameters.append(message.body.loadUnalignedIntBigEndian(offset: offset))
            offset += 4
        }
        return .init(parameters: parameters)
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func parameterDescription(logger: Logger) throws -> PostgresParameterDescriptionMessage {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresParameterDescriptionMessage")
        #endif
        return try PostgresParameterDescriptionMessage.parse(message: self)
    }
}