
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
                if let type = PostgresRawMessage.BackendType(rawValue: msg.type), type.isFinalMessage {
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
            case PostgresRawMessage.BackendType.bindComplete.rawValue:
                return try .bindComplete(msg.bindComplete(logger: logger))
            case PostgresRawMessage.BackendType.closeComplete.rawValue:
                return .closeComplete(try msg.closeComplete(logger: logger))
            case PostgresRawMessage.BackendType.commandComplete.rawValue:
                return .commandComplete(try msg.commandComplete(logger: logger))
            case PostgresRawMessage.BackendType.copyInResponse.rawValue:
                return .copyInResponse(try msg.copyInResponse(logger: logger))
            case PostgresRawMessage.BackendType.copyOutResponse.rawValue:
                return .copyOutResponse(try msg.copyOutResponse(logger: logger))
            case PostgresRawMessage.BackendType.dataRow.rawValue:
                return .dataRow(try msg.dataRow(logger: logger))
            case PostgresRawMessage.BackendType.emptyQueryResponse.rawValue:
                return .emptyQueryResponse(try msg.emptyQueryResponse(logger: logger))
            case PostgresRawMessage.BackendType.errorResponse.rawValue:
                return .errorResponse(try msg.errorResponse(logger: logger))
            case PostgresRawMessage.BackendType.functionCallResponse.rawValue:
                return .functionCallResponse(try msg.functionCallResponse(logger: logger))
            case PostgresRawMessage.BackendType.noData.rawValue:
                return .noData(try msg.noData(logger: logger))
            case PostgresRawMessage.BackendType.noticeResponse.rawValue:
                return .noticeResponse(try msg.noticeResponse(logger: logger))
            case PostgresRawMessage.BackendType.parseComplete.rawValue:
                return .parseComplete(try msg.parseComplete(logger: logger))
            case PostgresRawMessage.BackendType.portalSuspended.rawValue:
                return .portalSuspended(try msg.portalSuspend(logger: logger))
            case PostgresRawMessage.BackendType.readyForQuery.rawValue:
                return .readyForQuery(try msg.readyForQuery(logger: logger))
            case PostgresRawMessage.BackendType.rowDescription.rawValue:
                return .rowDescription(try msg.rowDescription(logger: logger))
            default:
                logger.warning("unknown message type: \(msg.type)")
                return .unknown(msg)
            }
        }
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public static func query(unsafeSQL: String) -> PostgresQueryMessage {
        return PostgresQueryMessage(unsafeSQL: unsafeSQL)
    }
}