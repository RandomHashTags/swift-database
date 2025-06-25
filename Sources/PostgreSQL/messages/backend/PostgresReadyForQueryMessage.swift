
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-READYFORQUERY
public struct PostgresReadyForQueryMessage: PostgresReadyForQueryMessageProtocol {
    public let transactionStatus:TransactionStatus

    @inlinable
    public init(transactionStatus: TransactionStatus) {
        self.transactionStatus = transactionStatus
    }
}

// MARK: Transaction status
extension PostgresReadyForQueryMessage {
    public enum TransactionStatus: UInt8, Sendable {
        case idle   = 73 // I
        case block  = 84 // T
        case failed = 69 // E
    }
}

// MARK: Parse
extension PostgresReadyForQueryMessage {
    @inlinable
    public static func parse(
        message: PostgresRawMessage
    ) throws -> Self {
        guard message.type == .Z else {
            throw PostgresError.readyForQuery("message type != .Z")
        }
        let status:UInt8 = message.body.loadUnalignedInt()
        guard let transactionStatus = TransactionStatus(rawValue: status) else {
            throw PostgresError.readyForQuery("malformed transaction status: \(status)")
        }
        return .init(transactionStatus: transactionStatus)
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func readyForQuery(logger: Logger) throws -> PostgresReadyForQueryMessage {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresReadyForQueryMessage")
        #endif
        return try PostgresReadyForQueryMessage.parse(message: self)
    }
}