
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-FUNCTIONCALLRESPONSE
public struct PostgresFunctionCallResponseMessage: PostgresFunctionCallResponseMessageProtocol {
    public var value:ByteBuffer?

    @inlinable
    public init(value: ByteBuffer?) {
        self.value = value
    }
}

// MARK: Parse
extension PostgresFunctionCallResponseMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage
    ) throws -> Self {
        guard message.type == .V else {
            throw PostgresError.functionCallResponse("message type != .V")
        }
        let lengthOfFunctionResult:Int32 = message.body.loadUnalignedInt()
        let value:ByteBuffer?
        if lengthOfFunctionResult <= 0 {
            value = nil
        } else {
            value = message.body.loadByteBufferBigEndian(offset: 4, count: Int(lengthOfFunctionResult))
        }
        return .init(value: value)
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func functionCallResponse(logger: Logger) throws -> PostgresFunctionCallResponseMessage {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresFunctionCallResponseMessage")
        #endif
        return try PostgresFunctionCallResponseMessage.parse(message: self)
    }
}