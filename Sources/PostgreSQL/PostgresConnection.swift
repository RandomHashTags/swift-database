

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

import Logging
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

public struct PostgresConnection: PostgresConnectionProtocol {
    public typealias QueryMessage = PostgresQueryMessage

    public var fileDescriptor:Int32
    public var logger:Logger

    @usableFromInline
    var backendKeyData:PostgresBackendKeyDataMessage?

    public init() {
        fileDescriptor = -1
        logger = Logger(label: "database.swift.postgresDisconnectedFileDescriptor")
    }
}

// MARK: Connect
extension PostgresConnection {
    @inlinable
    public mutating func establishConnection(storage: DatabaseStorageMethod) throws {
        switch storage {
        case .device(let address, let port):
            try establishConnection(address: address, port: port)
        case .memory: // TODO: support
            break
        }
    }

    @inlinable
    mutating public func establishConnection(address: String, port: UInt16) throws {
        guard fileDescriptor == -1 else {
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
        logger = Logger(label: "database.swift.postgresFileDescriptor\(fileDescriptor)")
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
        try establishConnection(address: address, port: port)
        var startupMessage = PostgresStartupMessage(parameters: [
            "user": user,
            "database" : database
        ])
        try sendMessage(&startupMessage)
        try authenticate()
    }
}

// MARK: Authenticate
extension PostgresConnection {
    @inlinable
    mutating func authenticate() throws {
        var authenticationStatus = AuthenticationStatus.loading
        while authenticationStatus == .loading {
            try readMessage { msg in
                switch msg.type {
                case PostgresRawMessage.BackendType.authentication.rawValue:
                    try msg.authentication(logger: logger) { auth in
                        switch auth {
                        case .ok:
                            authenticationStatus = .success
                        default:
                            throw PostgresError.authentication("not yet supported: \(auth)")
                        }
                    }
                case PostgresRawMessage.BackendType.errorResponse.rawValue:
                    try msg.errorResponse(logger: logger) {
                        throw PostgresError.authentication("received errorResponse: \($0.values)")
                    }
                case PostgresRawMessage.BackendType.negotiateProtocolVersion.rawValue:
                    throw PostgresError.authentication("not yet supported: protocol version negotation")
                default:
                    throw PostgresError.authentication("unhandled message type: \(msg.type)")
                }
            }
        }
        try waitUntilReadyForQuery()
    }
}

// MARK: Wait until R4Q
extension PostgresConnection {
    @inlinable
    mutating func waitUntilReadyForQuery() throws {
        var ready = false
        while !ready {
            try readMessage { msg in
                switch msg.type {
                case PostgresRawMessage.BackendType.backendKeyData.rawValue:
                    try msg.backendKeyData(logger: logger, {
                        backendKeyData = $0 // TODO: fix
                    })
                case PostgresRawMessage.BackendType.parameterStatus.rawValue:
                    break
                case PostgresRawMessage.BackendType.readyForQuery.rawValue:
                    try msg.readyForQuery(logger: logger, { _ in
                        ready = true
                    })
                case PostgresRawMessage.BackendType.noticeResponse.rawValue:
                    try msg.noticeResponse(logger: logger, { _ in
                        logger.warning("received notice response")
                    })
                case PostgresRawMessage.BackendType.errorResponse.rawValue:
                    try msg.errorResponse(logger: logger) {
                        throw PostgresError.readyForQuery("waitUntilReadyForQuery;received errorResponse: \($0.values)")
                    }
                default:
                    throw PostgresError.readyForQuery("waitUntilReadyForQuery;unhandled message type: \(msg.type)")
                }
            }
        }
        #if DEBUG
        logger.info("ready for query")
        #endif
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

// MARK: Shutdown connection
extension PostgresConnection {
    @inlinable
    public func shutdownConnection() {
        closeFileDescriptor()
    }
}

// MARK: Query
extension PostgresConnection {
    public func query(_ query: String) async throws -> QueryMessage.Response {
        var payload = RawMessage.query(query)
        try sendMessage(&payload)
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try readMessage { msg in
                    try QueryMessage.Response.parse(logger: logger, msg: msg, {
                        continuation.resume(returning: $0)
                    })
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}