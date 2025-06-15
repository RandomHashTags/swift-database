
import Logging
import PostgreSQLBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-READYFORQUERY
public struct PostgresReadyForQueryMessage: PostgresReadyForQueryMessageProtocol {
    public let transactionStatus:TransactionStatus

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
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .Z else {
            throw PostgresError.readyForQuery("message type != .Z")
        }
        let status:UInt8 = message.body.loadUnalignedInt(offset: 4)
        guard let transactionStatus = TransactionStatus(rawValue: status) else {
            throw PostgresError.readyForQuery("malformed transaction status: \(status)")
        }
        try closure(.init(transactionStatus: transactionStatus))
    }
}

// MARK: Convenience
extension PostgresRawMessage {
    @inlinable
    public func readyForQuery(logger: Logger, _ closure: (consuming PostgresReadyForQueryMessage) throws -> Void) throws {
        #if DEBUG
        logger.info("Parsing PostgresRawMessage as PostgresReadyForQueryMessage")
        #endif
        try PostgresReadyForQueryMessage.parse(message: self, closure)
    }
}