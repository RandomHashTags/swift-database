
import Logging
import PostgreSQLBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-ERRORRESPONSE
public struct PostgresErrorResponseMessage: PostgresErrorResponseMessageProtocol {
    public var values:[String] // TODO: support binary format

    public init(values: [String]) {
        self.values = values
    }
}

// MARK: Parse
extension PostgresErrorResponseMessage {
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .E else {
            throw PostgresError.errorResponse("message type != .E")
        }
        let length:Int32 = message.body.loadUnalignedInt() - 4
        var startIndex = 4
        var values = [String]()
        while startIndex < length {
            let fieldType:UInt8 = message.body.loadUnalignedIntBigEndian(offset: 4)
            startIndex += 1
            if fieldType == 0 {
                break
            } else {
                if let terminatorIndex = message.body[startIndex...].firstIndex(of: 0) {
                    let stringLength = terminatorIndex.distance(to: startIndex) + 1
                    values.append(message.body.loadNullTerminatedStringBigEndian(offset: startIndex, count: stringLength))
                    startIndex += stringLength
                } else {
                    throw PostgresError.errorResponse("didn't find string terminator (0) in message body after index \(startIndex)")
                }
            }
        }
        try closure(.init(values: values))
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func errorResponse(logger: Logger, _ closure: (consuming PostgresErrorResponseMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresErrorResponseMessage")
        #endif
        try PostgresErrorResponseMessage.parse(message: self, closure)
    }
}