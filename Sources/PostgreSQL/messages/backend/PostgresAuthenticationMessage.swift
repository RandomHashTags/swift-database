
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

public enum PostgresAuthenticationMessage: PostgresAuthenticationMessageProtocol, @unchecked Sendable {
    case ok
    case kerberosV5
    case cleartextPassword
    case md5Password(salt: Int32)
    case gss
    case gssContinue(data: UnsafeMutableBufferPointer<UInt8>)
    case sspi
    case sasl(names: [String])
    case saslContinue(data: UnsafeMutableBufferPointer<UInt8>)
    case saslFinal(data: UnsafeMutableBufferPointer<UInt8>)
}

// MARK: Parse
extension PostgresAuthenticationMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .R else {
            throw PostgresError.authentication("message type != .R")
        }
        let length:Int32 = message.body.loadUnalignedIntBigEndian()
        let id:UInt8 = message.body.loadUnalignedIntBigEndian(offset: 4)
        switch id {
        case 0:
            try closure(.ok)
        case 2:
            try closure(.kerberosV5)
        case 3:
            try closure(.cleartextPassword)
        case 5:
            try closure(.md5Password(salt: message.body.loadUnalignedIntBigEndian(offset: 8)))
        case 7:
            try closure(.gss)
        case 8:
            let capacity = Int(length - 8)
            try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity, { buffer in
                buffer.copyBuffer(message.body.baseAddress! + 8, count: capacity, to: 0)
                try closure(.gssContinue(data: buffer))
            })
        case 9:
            try closure(.sspi)
        case 10:
            var names = [String]()
            var startIndex = 8
            var i = 8
            while i < length {
                guard let (string, length) = message.body.loadNullTerminatedStringBigEndian(offset: startIndex) else {
                    throw PostgresError.authentication("failed to load string from message body after index \(startIndex)")
                }
                names.append(string)
                i += length
                startIndex = i
            }
            try closure(.sasl(names: names))
        case 11:
            let capacity = Int(length - 8)
            try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity, { buffer in
                buffer.copyBuffer(message.body, offset: 8, count: capacity, to: 0)
                try closure(.saslContinue(data: buffer))
            })
        case 12:
            let capacity = Int(length - 8)
            try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity, { buffer in
                buffer.copyBuffer(message.body, offset: 8, count: capacity, to: 0)
                try closure(.saslFinal(data: buffer))
            })
        default:
            throw PostgresError.authentication("length=\(length);unhandled id: \(id)")
        }
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func authentication(logger: Logger, _ closure: (consuming PostgresAuthenticationMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresAuthenticationMessage")
        #endif
        try PostgresAuthenticationMessage.parse(message: self, closure)
    }
}