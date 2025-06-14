
import SQLBlueprint
import PostgreSQLBlueprint

extension PostgresRawMessage {
    public enum Authentication: PostgresAuthenticationMessageProtocol, @unchecked Sendable {

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
}

// MARK: Parse
extension PostgresRawMessage.Authentication {
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .R else {
            throw PostgresError.authentication("message type != .R")
        }
        let length:Int32 = message.body.loadUnalignedIntBigEndian()
        switch length {
        case 8:
            let id:UInt8 = message.body.loadUnalignedIntBigEndian(offset: 4)
            switch id {
            case 0:
                try closure(.ok)
            case 2:
                try closure(.kerberosV5)
            case 3:
                try closure(.cleartextPassword)
            case 7:
                try closure(.gss)
            case 9:
                try closure(.sspi)
            default:
                throw PostgresError.authentication("length=\(length);unhandled id: \(id)")
            }
        case 12:
            try closure(.md5Password(salt: message.body.loadUnalignedIntBigEndian(offset: 8)))
        default:
            let id:UInt8 = message.body.loadUnalignedIntBigEndian(offset: 4)
            switch id {
            case 8:
                let capacity = Int(length - 8)
                try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity, { buffer in
                    buffer.copyBuffer(message.body.baseAddress! + 8, count: capacity, to: 0)
                    try closure(.gssContinue(data: buffer))
                })
            case 10:
                var names = [String]()
                var startIndex = 8
                var i = 8
                while i < length {
                    if message.body[i] == 0 {
                        names.append(message.body.loadNullTerminatedString(offset: startIndex))
                        i += 1
                        startIndex = i
                    } else {
                        i += 1
                    }
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
                throw PostgresError.authentication("length=\(length);unhandled id: \(length)")
            }
        }
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func authentication(_ closure: (consuming Authentication) throws -> Void) throws {
        try Authentication.parse(message: self, closure)
    }
}