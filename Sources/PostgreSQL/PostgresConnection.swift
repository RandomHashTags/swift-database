
#if canImport(Android)
import Android
#elseif canImport(Bionic)
import Bionic
#elseif canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(WASILibc)
import WASILibc
#elseif canImport(Windows)
import Windows
#elseif canImport(WinSDK)
import WinSDK
#endif

import Logging
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

public struct PostgresConnection: PostgresConnectionProtocol {
    public typealias QueryMessage = PostgresQueryMessage

    @usableFromInline
    var _fileDescriptor:Int32

    @usableFromInline
    var _logger:Logger

    @usableFromInline
    var _configuration:Configuration

    @usableFromInline
    var backendKeyData:PostgresBackendKeyDataMessage?

    public init() {
        _fileDescriptor = -1
        _logger = Logger(label: "database.swift.postgresDisconnectedFileDescriptor")
        _configuration = Configuration()
    }

    @inlinable
    public var fileDescriptor: Int32 {
        _fileDescriptor
    }

    @inlinable
    public var logger: Logger {
        _logger
    }

    @inlinable
    public var configuration: Configuration {
        _configuration
    }
}

// MARK: Configuration
extension PostgresConnection {
    public struct Configuration: Sendable {
        @usableFromInline
        var dictionary:[String:String] = [:]

        @inlinable
        public mutating func update(_ msg: PostgresParameterStatusMessage) {
            dictionary[msg.parameter] = msg.value
        }

        @inlinable public var inHotStandby: String? { dictionary["in_hot_standby"] }
        @inlinable public var integerDatetimes: String? { dictionary["integer_datetimes"] }
        @inlinable public var timeZone: String? { dictionary["TimeZone"] }
        @inlinable public var intervalStyle: String? { dictionary["IntervalStyle"] }
        @inlinable public var isSuperuser: String? { dictionary["is_superuser"] }
        @inlinable public var applicationName: String? { dictionary["application_name"] }
        @inlinable public var defaultTransactionReadOnly: String? { dictionary["default_transaction_read_only"] }
        @inlinable public var scramIterations: String? { dictionary["scram_iterations"] }
        @inlinable public var dateStyle: String? { dictionary["DateStyle"] }
        @inlinable public var standardConformingStrings: String? { dictionary["standard_conforming_strings"] }
        @inlinable public var sessionAuthorization: String? { dictionary["session_authorization"] }
        @inlinable public var clientEncoding: String? { dictionary["client_encoding"] }
        @inlinable public var serverVersion: String? { dictionary["server_version"] }
        @inlinable public var serverEncoding: String? { dictionary["server_encoding"] }
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
    public mutating func establishConnection(address: String, port: UInt16) throws {
        guard fileDescriptor == -1 else {
            throw PostgresError.connectionAlreadyEstablished()
        }
        _fileDescriptor = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
        guard fileDescriptor >= 0 else {
            throw PostgresError.socketFailure("errno=\(errno)")
        }

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
        guard connectResult == 0 else {
            throw PostgresError.connectionFailure("errno=\(errno)")
        }
        let flags = fcntl(_fileDescriptor, F_GETFL, 0)
        guard flags != -1 else {
            throw PostgresError.socketFailure("flags == -1 for file descriptor \(_fileDescriptor)")
        }
        let didNonblocking = fcntl(_fileDescriptor, F_SETFL, flags | O_NONBLOCK)
        guard didNonblocking != -1 else {
            throw PostgresError.socketFailure("failed to make file descriptor (\(_fileDescriptor)) nonblocking")
        }

        _logger = Logger(label: "database.swift.postgresFileDescriptor\(fileDescriptor)")
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
        try await sendMessage(&startupMessage)
        try await authenticate()
    }
}

// MARK: Authenticate
extension PostgresConnection {
    @inlinable
    mutating func authenticate() async throws {
        var authenticationStatus = AuthenticationStatus.loading
        while authenticationStatus == .loading {
            let msg = try await readMessage()
            switch msg.type {
            case PostgresMessageBackendType.authentication.rawValue:
                let auth = try msg.authentication(logger: logger)
                switch auth {
                case .ok:
                    authenticationStatus = .success
                default:
                    throw PostgresError.authentication("not yet supported: \(auth)")
                }
            case PostgresMessageBackendType.errorResponse.rawValue:
                let response = try msg.errorResponse(logger: logger)
                throw PostgresError.authentication("received errorResponse: \(response.values)")
            case PostgresMessageBackendType.negotiateProtocolVersion.rawValue:
                throw PostgresError.authentication("not yet supported: protocol version negotiation")
            default:
                throw PostgresError.authentication("unhandled message type: \(msg.type)")
            }
        }
        #if DEBUG
        logger.notice("authentication successful")
        #endif
        let logger = logger
        var _configuration = _configuration
        var backendKeyData:PostgresBackendKeyDataMessage? = nil
        try await readUntilReadyForQuery { msg in
            switch msg.type {
            case PostgresMessageBackendType.backendKeyData.rawValue:
                backendKeyData = try msg.backendKeyData(logger: logger)
            case PostgresMessageBackendType.errorResponse.rawValue:
                let response = try msg.errorResponse(logger: logger)
                throw PostgresError.authentication("readUntilReadyForQuery;received errorResponse: \(response.values)")
            case PostgresMessageBackendType.noticeResponse.rawValue:
                let response = try msg.noticeResponse(logger: logger)
                logger.warning("received notice response: \(response)")
            case PostgresMessageBackendType.parameterStatus.rawValue:
                let response = try msg.parameterStatus(logger: logger)
                _configuration.update(response)
            default:
                throw PostgresError.authentication("readUntilReadyForQuery;unhandled message type: \(msg.type)")
            }
        }
        self._configuration = _configuration
        self.backendKeyData = backendKeyData
    }
}

// MARK: Wait until R4Q
extension PostgresConnection {
    @inlinable
    public mutating func readUntilReadyForQuery(
        _ onMessage: (PostgresRawMessage) throws -> Void
    ) async throws {
        #if DEBUG
        logger.notice("reading until a Ready For Query message is received...")
        #endif
        var ready = false
        while !ready {
            let msg = try await readMessage()
            if msg.type == PostgresMessageBackendType.readyForQuery.rawValue {
                ready = true
                break
            }
            try onMessage(msg)
        }
        #if DEBUG
        logger.notice("ready for query")
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
    @inlinable
    public mutating func query(
        unsafeSQL: String,
        _ onMessage: (RawMessage) throws -> Void
    ) async throws -> QueryMessage.Response {
        var payload = RawMessage.query(unsafeSQL: unsafeSQL)
        try await sendMessage(&payload)
        let msg = try await readMessage()
        let response = try QueryMessage.Response.parse(logger: logger, msg: msg)
        if PostgresMessageBackendType(rawValue: msg.type)?.isFinalMessage ?? false {
            try await readUntilReadyForQuery(onMessage)
        }
        return response
    }
}