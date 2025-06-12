
import SQLBlueprint
import SwiftDatabaseBlueprint

public struct PostgresStartupMessage: PostgresMessageProtocol {
    public let protocolVersion:Int32
    public var user:String
    public var database:String

    public init(
        protocolVersion: Int32 = 196608, // protocol version 3.0 (0x00030000 = 196608)
        user: String,
        database: String
    ) {
        self.protocolVersion = protocolVersion
        self.user = user
        self.database = database
    }

    @inlinable
    public mutating func write<Connection: PostgresConnectionProtocol & ~Copyable>(to connection: borrowing Connection) throws {
        try Self.createMessage(protocolVersion: protocolVersion, user: &user, database: &database) { p in
            try connection.writeBuffer(p.baseAddress!, length: p.count)
        }
    }
}

// MARK: Message
extension PostgresStartupMessage {
    @inlinable
    static func createMessage(
        protocolVersion: Int32,
        user: inout String,
        database: inout String,
        _ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void
    ) rethrows {
        try createBody(user: &user, database: &database) { bodyBuffer in
            let capacity = bodyBuffer.count + 4
            try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity, { buffer in
                var index = 0
                withUnsafeBytes(of: capacity.bigEndian, {
                    for i in 0..<$0.count {
                        buffer[i] = $0[i]
                        index += 1
                    }
                })
                withUnsafeBytes(of: protocolVersion, {
                    for i in 0..<$0.count {
                        buffer[index] = $0[i]
                        index += 1
                    }
                })
                for i in 0..<bodyBuffer.count {
                    buffer[index] = bodyBuffer[i]
                    index += 1
                }
                try closure(buffer)
            })
        }
    }
}

// MARK: Body
extension PostgresStartupMessage {
    @inlinable
    static func createBody(
        user: inout String,
        database: inout String,
        _ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void
    ) rethrows {
        try user.withUTF8 { userBuffer in
            try database.withUTF8 { databaseBuffer in
                // 6 = user payload
                // 10 = database payload
                // 1 = terminator
                let bodyCapacity = 6 + userBuffer.count + 10 + databaseBuffer.count + 1
                try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: bodyCapacity, { buffer in
                    buffer.initialize(repeating: 0)
                    buffer[0] = .u
                    buffer[1] = .s
                    buffer[2] = .e
                    buffer[3] = .r
                    
                    var index = 5
                    for i in 0..<userBuffer.count {
                        buffer[index] = userBuffer[i]
                        index += 1
                    }
                    index += 1 // skip terminator

                    buffer[index] = .d
                    index += 1
                    buffer[index] = .a
                    index += 1
                    buffer[index] = .t
                    index += 1
                    buffer[index] = .a
                    index += 1
                    buffer[index] = .b
                    index += 1
                    buffer[index] = .a
                    index += 1
                    buffer[index] = .s
                    index += 1
                    buffer[index] = .e
                    index += 1
                    index += 1 // skip terminator
                    for i in 0..<databaseBuffer.count {
                        buffer[index] = databaseBuffer[i]
                        index += 1
                    }
                    index += 1 // skip terminator
                    try closure(buffer)
                })
            }
        }
    }
}