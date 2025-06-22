
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
    public mutating func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        try _unsafeSQL.withUTF8 { sqlBuffer in
            let capacity = 5 + sqlBuffer.count + 1
            try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: capacity, { buffer in
                var i = 0
                buffer.writePostgresMessageHeader(type: .Q, capacity: capacity, to: &i)
                buffer.copyBuffer(sqlBuffer, to: &i)
                buffer[i] = 0
                try closure(buffer)
            })
        }
    }
}

// MARK: Write
extension PostgresQueryMessage {
    @inlinable
    public mutating func write<Connection: PostgresConnectionProtocol & ~Copyable>(to connection: borrowing Connection) throws {
        try payload {
            try connection.writeBuffer($0.baseAddress!, length: $0.count)
        }
    }
}

// MARK: Response
extension PostgresQueryMessage {
    public enum Response: PostgresQueryMessageResponseProtocol {
        case commandComplete(PostgresCommandCompleteMessage)
        case copyInResponse(PostgresCopyInResponseMessage)
        case copyOutResponse(PostgresCopyOutResponseMessage)
        case rowDescription(PostgresRowDescriptionMessage)
        case dataRow(PostgresDataRowMessage)
        case emptyQueryResponse(PostgresEmptyQueryResponseMessage)
        case errorResponse(PostgresErrorResponseMessage)
        case readyForQuery(PostgresReadyForQueryMessage)
        case noticeResponse(PostgresNoticeResponseMessage)
        case unknown(PostgresRawMessage)

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
        public static func parse(logger: Logger, msg: PostgresRawMessage, _ closure: (Response) throws -> Void) throws {
            switch msg.type {
            case PostgresRawMessage.BackendType.close.rawValue: // command complete
                try msg.commandComplete(logger: logger, {
                    try closure(.commandComplete($0))
                })
            case PostgresRawMessage.BackendType.copyInResponse.rawValue:
                try msg.copyInResponse(logger: logger, {
                    try closure(.copyInResponse($0))
                })
            case PostgresRawMessage.BackendType.copyOutResponse.rawValue:
                try msg.copyOutResponse(logger: logger, {
                    try closure(.copyOutResponse($0))
                })
            case PostgresRawMessage.BackendType.rowDescription.rawValue:
                try msg.rowDescription(logger: logger, {
                    try closure(.rowDescription($0))
                })
            case PostgresRawMessage.BackendType.dataRow.rawValue:
                try msg.dataRow(logger: logger, {
                    try closure(.dataRow($0))
                })
            case PostgresRawMessage.BackendType.emptyQueryResponse.rawValue:
                try msg.emptyQueryResponse(logger: logger, {
                    try closure(.emptyQueryResponse($0))
                })
            case PostgresRawMessage.BackendType.readyForQuery.rawValue:
                try msg.readyForQuery(logger: logger, {
                    try closure(.readyForQuery($0))
                })
            case PostgresRawMessage.BackendType.noticeResponse.rawValue:
                try msg.noticeResponse(logger: logger, {
                    try closure(.noticeResponse($0))
                })
            case PostgresRawMessage.BackendType.errorResponse.rawValue:
                try msg.errorResponse(logger: logger, {
                    try closure(.errorResponse($0))
                })
            default:
                logger.warning("unknown message type: \(msg.type)")
                try closure(.unknown(msg))
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