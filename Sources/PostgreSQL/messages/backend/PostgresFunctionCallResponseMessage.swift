
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-FUNCTIONCALLRESPONSE
public struct PostgresFunctionCallResponseMessage: PostgresFunctionCallResponseMessageProtocol {
    public var value:String? // TODO: support binary format

    @inlinable
    public init(value: String?) {
        self.value = value
    }
}

// MARK: Parse
extension PostgresFunctionCallResponseMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .V else {
            throw PostgresError.functionCallResponse("message type != .V")
        }
        let lengthOfFunctionResult:Int32 = message.body.loadUnalignedInt(offset: 4)
        let value:String?
        if lengthOfFunctionResult <= 0 {
            value = nil
        } else {
            value = message.body.loadNullTerminatedStringBigEndian(offset: 8, count: Int(lengthOfFunctionResult))
        }
        try closure(.init(value: value))
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func functionCallResponse(logger: Logger, _ closure: (consuming PostgresFunctionCallResponseMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresFunctionCallResponseMessage")
        #endif
        try PostgresFunctionCallResponseMessage.parse(message: self, closure)
    }
}