
import Logging
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-QUERY
public struct PostgresQueryMessage: PostgresQueryMessageProtocol {
    public typealias ConcreteResponse = Response

    public var sql:String

    @inlinable
    public init(_ sql: String) {
        self.sql = sql
    }
}

// MARK: Payload
extension PostgresQueryMessage {
    @inlinable
    public mutating func payload(_ closure: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        try sql.withUTF8 { sqlBuffer in
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
    public enum Response: Sendable {
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
            default:
                try closure(.unknown(msg))
            }
        }
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public static func query(_ sql: String) -> PostgresQueryMessage {
        return PostgresQueryMessage(sql)
    }
}