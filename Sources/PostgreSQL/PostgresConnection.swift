

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
import SwiftDatabaseBlueprint

public struct PostgresConnection: PostgresConnectionProtocol {
    public var fileDescriptor:Int32

    public init() {
        fileDescriptor = -1
    }
}

// MARK: Connect
extension PostgresConnection {
    @inlinable
    public mutating func establishConnection(address: String, port: UInt16) throws {
        guard fileDescriptor >= 0 else {
            throw PostgresError.connectionAlreadyEstablished()
        }
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
        var startupMessage = PostgresRawMessage.StartupMessage(parameters: [
            "user": user,
            "database" : database
        ])
        try startupMessage.write(to: self)

        try authenticate()
    }
}

// MARK: Authenticate
extension PostgresConnection {
    @inlinable
    func authenticate() throws {
        var authenticationStatus = AuthenticationStatus.loading
        while authenticationStatus == .loading {
            try readMessage { msg in
                switch msg.type {
                case PostgresRawMessage.BackendType.authentication.rawValue:
                    try msg.authentication { auth in
                        switch auth {
                        case .ok:
                            authenticationStatus = .success
                        default:
                            throw PostgresError.authentication("not yet supported: \(auth)")
                        }
                    }
                case PostgresRawMessage.BackendType.readyForQuery.rawValue:
                    break
                default:
                    throw PostgresError.authentication("unhandled message type: \(msg.type)")
                }
            }
        }
    }
}

// MARK: Authentication status
extension PostgresConnection {
    public enum AuthenticationStatus: UInt8 {
        case loading
        case success
        case failed
    }
}

// MARK: Read message
extension PostgresConnection {
    @inlinable
    public func readMessage(_ closure: (PostgresRawMessage) throws -> Void) throws {
        var header = InlineArray<5, UInt8>(repeating: 0)
        var span = header.mutableSpan
        try span.withUnsafeMutableBufferPointer { p in
            guard receive(baseAddress: p.baseAddress!, length: 5) == 5 else {
                throw PostgresError.readMessage("receive != 5")
            }
        }
        let type = header[0]
        let length = Int(header.span.withUnsafeBytes { $0[1..<5].load(as: UInt32.self) }) - 4
        try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: length, { buffer in
            _ = receive(baseAddress: buffer.baseAddress!, length: length)
            try closure(PostgresRawMessage(type: type, body: buffer))
        })
    }
}

// MARK: Shutdown connection
extension PostgresConnection {
    @inlinable
    public func shutdownConnection() {
        closeFileDescriptor()
    }
}

// MARK: Query
extension PostgresConnection {
    public func query(_ query: String) async throws -> RawMessage { // TODO: return a concrete query response
        var payload = RawMessage.query(query)
        try payload.write(to: self)
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try readMessage { msg in
                    continuation.resume(returning: msg)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}