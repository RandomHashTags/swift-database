

#if canImport(Android)
import Android
#elseif canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(WinSDK)
import WinSDK
#endif

import PostgreSQLBlueprint
import SQLBlueprint

public struct PostgresConnection: PostgresConnectionProtocol {
    public var fileDescriptor:Int32

    public init() {
        fileDescriptor = -1
    }
}

// MARK: Establish
extension PostgresConnection {
    @inlinable
    public mutating func establish(
        address: String,
        port: UInt16,
        user: String,
        database: String
    ) async throws {
        guard !isConnected else { fatalError("already established") }
        fileDescriptor = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
        guard fileDescriptor >= 0 else { fatalError("socket error") }

        var addrIn = sockaddr_in()
        addrIn.sin_family = sa_family_t(AF_INET)
        addrIn.sin_port = port.bigEndian
        addrIn.sin_addr.s_addr = inet_addr(address)

        var addr = sockaddr()
        memcpy(&addr, &addrIn, MemoryLayout<sockaddr_in>.size)

        let connectResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(fileDescriptor, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard connectResult == 0 else { fatalError("connect error") }

        var startupMessage = PostgresStartupMessage(user: user, database: database)
        try startupMessage.write(to: self)

        /*var authenticated = false
        while !authenticated {
            try readMessage { msg in
            }
        }*/
    }
}

// MARK: Read message
extension PostgresConnection {
    @inlinable
    public func readMessage(_ closure: (PostgresMessage) throws -> Void) rethrows {
        var header = InlineArray<5, UInt8>(repeating: 0)
        header.mutableSpan.withUnsafeBufferPointer { p in
            guard read(fileDescriptor, .init(mutating: p.baseAddress!), 5) == 5 else {
                fatalError("PostgresConnection;readMessage;read != 5")
            }
        }
        let type = header[0]
        let length = Int(header.span.withUnsafeBytes { $0[1..<5].load(as: UInt32.self) }) - 4
        try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: length, { buffer in
            _ = read(fileDescriptor, buffer.baseAddress, length)
            try closure(PostgresMessage(type: type, body: buffer))
        })
    }
}