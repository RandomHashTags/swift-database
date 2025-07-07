
import Logging
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-QUERY
public struct PostgresQueryMessage: PostgresQueryMessageProtocol {
    public typealias ConcreteResponse = Response

    @usableFromInline
    var _unsafeSQL:String

    @inlinable
    public init(unsafeSQL: String) {
        self._unsafeSQL = unsafeSQL
    }

    @inlinable
    public var unsafeSQL: String {
        _unsafeSQL
    }
}

// MARK: Payload
extension PostgresQueryMessage {
    @inlinable
    public mutating func payload() -> ByteBuffer {
        return _unsafeSQL.withUTF8 { sqlBuffer in
            let capacity = 5 + sqlBuffer.count + 1
            let buffer = ByteBuffer(capacity: capacity)
            var i = 0
            buffer.writePostgresMessageHeader(type: .Q, capacity: capacity, to: &i)
            buffer.copyBuffer(sqlBuffer, to: &i)
            buffer[i] = 0
            return buffer
        }
    }
}

// MARK: Write
extension PostgresQueryMessage {
    @inlinable
    public mutating func write<Connection: PostgresConnectionProtocol & ~Copyable>(
        to connection: borrowing Connection
    ) async throws {
        try await connection.writeBuffer(payload())
    }
}

// MARK: Response
extension PostgresQueryMessage {
    public enum Response: PostgresQueryMessageResponseProtocol {
        case bindComplete(PostgresBindCompleteMessage)
        case closeComplete(PostgresCloseCompleteMessage)
        case commandComplete(PostgresCommandCompleteMessage)
        case copyInResponse(PostgresCopyInResponseMessage)
        case copyOutResponse(PostgresCopyOutResponseMessage)
        case dataRow(PostgresDataRowMessage)
        case emptyQueryResponse(PostgresEmptyQueryResponseMessage)
        case functionCallResponse(PostgresFunctionCallResponseMessage)
        case noData(PostgresNoDataMessage)
        case noticeResponse(PostgresNoticeResponseMessage)
        case errorResponse(PostgresErrorResponseMessage)
        case parseComplete(PostgresParseCompleteMessage)
        case portalSuspended(PostgresPortalSuspendedMessage)
        case readyForQuery(PostgresReadyForQueryMessage)
        case rowDescription(PostgresRowDescriptionMessage)
        
        case unknown(PostgresRawMessage)

        public typealias DataRowMessage = PostgresDataRowMessage
        public typealias RowDescriptionMessage = PostgresRowDescriptionMessage

        @discardableResult
        @inlinable
        public func requireNotError() throws -> Self {
            switch self {
            case .errorResponse(let msg):
                throw PostgresError.errorResponse(msg.values.joined(separator: " "))
            case .unknown(let msg):
                throw PostgresError.errorResponse("unknown message type: \(msg.type)")
            default:
                break
            }
            return self
        }

        @inlinable
        public func waitUntilReadyForQuery<T: PostgresConnectionProtocol & ~Copyable>(
            on connection: inout T,
            _ onMessage: (PostgresRawMessage) throws -> Void = { _ in }
        ) async throws {
            switch self {
            case .bindComplete,
                    .emptyQueryResponse,
                    .errorResponse,
                    .functionCallResponse,
                    .closeComplete,
                    .noData,
                    .parseComplete,
                    .portalSuspended:
                break
            case .unknown(let msg):
                if let type = PostgresMessageBackendType(rawValue: msg.type), type.isFinalMessage {
                    break
                } else {
                    return
                }
            default:
                return
            }
            try await connection.waitUntilReadyForQuery(onMessage)
        }

        @inlinable
        public static func parse(
            logger: Logger,
            msg: PostgresRawMessage
        ) throws -> Self {
            switch msg.type {
            case PostgresMessageBackendType.bindComplete.rawValue:
                return try .bindComplete(msg.bindComplete(logger: logger))
            case PostgresMessageBackendType.closeComplete.rawValue:
                return try .closeComplete(msg.closeComplete(logger: logger))
            case PostgresMessageBackendType.commandComplete.rawValue:
                return try .commandComplete(msg.commandComplete(logger: logger))
            case PostgresMessageBackendType.copyInResponse.rawValue:
                return try .copyInResponse(msg.copyInResponse(logger: logger))
            case PostgresMessageBackendType.copyOutResponse.rawValue:
                return try .copyOutResponse(msg.copyOutResponse(logger: logger))
            case PostgresMessageBackendType.dataRow.rawValue:
                return try .dataRow(msg.dataRow(logger: logger))
            case PostgresMessageBackendType.emptyQueryResponse.rawValue:
                return try .emptyQueryResponse(msg.emptyQueryResponse(logger: logger))
            case PostgresMessageBackendType.errorResponse.rawValue:
                return try .errorResponse(msg.errorResponse(logger: logger))
            case PostgresMessageBackendType.functionCallResponse.rawValue:
                return try .functionCallResponse(msg.functionCallResponse(logger: logger))
            case PostgresMessageBackendType.noData.rawValue:
                return try .noData(msg.noData(logger: logger))
            case PostgresMessageBackendType.noticeResponse.rawValue:
                return try .noticeResponse(msg.noticeResponse(logger: logger))
            case PostgresMessageBackendType.parseComplete.rawValue:
                return try .parseComplete(msg.parseComplete(logger: logger))
            case PostgresMessageBackendType.portalSuspended.rawValue:
                return try .portalSuspended(msg.portalSuspend(logger: logger))
            case PostgresMessageBackendType.readyForQuery.rawValue:
                return try .readyForQuery(msg.readyForQuery(logger: logger))
            case PostgresMessageBackendType.rowDescription.rawValue:
                return try .rowDescription(msg.rowDescription(logger: logger))
            default:
                logger.warning("unknown message type: \(msg.type)")
                return .unknown(msg)
            }
        }
    }
}
extension PostgresQueryMessage.Response {
    @inlinable
    public func asDataRow() -> DataRowMessage? {
        if case let .dataRow(msg) = self {
            return msg
        }
        return nil
    }

    @inlinable
    public func asRowDescription() -> RowDescriptionMessage? {
        if case let .rowDescription(msg) = self {
            return msg
        }
        return nil
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public static func query(unsafeSQL: String) -> PostgresQueryMessage {
        return PostgresQueryMessage(unsafeSQL: unsafeSQL)
    }
}