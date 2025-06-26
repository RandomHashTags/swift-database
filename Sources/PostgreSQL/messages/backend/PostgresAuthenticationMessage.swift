
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

public enum PostgresAuthenticationMessage: PostgresAuthenticationMessageProtocol, @unchecked Sendable {
    case ok
    case kerberosV5
    case cleartextPassword
    case md5Password(salt: Int32)
    case gss
    case gssContinue(data: ByteBuffer)
    case sspi
    case sasl(names: [String])
    case saslContinue(data: ByteBuffer)
    case saslFinal(data: ByteBuffer)
}

// MARK: Parse
extension PostgresAuthenticationMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage
    ) throws -> Self {
        guard message.type == .R else {
            throw PostgresError.authentication("message type != .R")
        }
        let length:Int32 = message.bodyCount
        let id:Int32 = message.body.loadUnalignedIntBigEndian()
        switch id {
        case 0:
            return .ok
        case 2:
            return .kerberosV5
        case 3:
            return .cleartextPassword
        case 5:
            return .md5Password(salt: message.body.loadUnalignedIntBigEndian(offset: 4))
        case 7:
            return .gss
        case 8:
            let capacity = Int(length - 4)
            let buffer = ByteBuffer(capacity: capacity)
            buffer.copyBuffer(message.body.baseAddress! + 4, count: capacity, to: 0)
            return .gssContinue(data: buffer)
        case 9:
            return .sspi
        case 10:
            var names = [String]()
            var startIndex = 4
            var i = 4
            while i < length {
                guard let (string, length) = message.body.loadNullTerminatedStringBigEndian(offset: startIndex) else {
                    throw PostgresError.authentication("failed to load string from message body after index \(startIndex)")
                }
                names.append(string)
                i += length
                startIndex = i
            }
            return .sasl(names: names)
        case 11:
            let capacity = Int(length - 4)
            let buffer = ByteBuffer(capacity: capacity)
            buffer.copyBuffer(message.body.baseAddress! + 4, count: capacity, to: 0)
            return .saslContinue(data: buffer)
        case 12:
            let capacity = Int(length - 4)
            let buffer = ByteBuffer(capacity: capacity)
            buffer.copyBuffer(message.body.baseAddress! + 4, count: capacity, to: 0)
            return .saslFinal(data: buffer)
        default:
            throw PostgresError.authentication("length=\(length);unhandled id: \(id)")
        }
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func authentication(logger: Logger) throws -> PostgresAuthenticationMessage {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresAuthenticationMessage")
        #endif
        return try PostgresAuthenticationMessage.parse(message: self)
    }
}