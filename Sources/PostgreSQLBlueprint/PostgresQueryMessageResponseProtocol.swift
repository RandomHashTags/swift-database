
import Logging
import SQLBlueprint

public protocol PostgresQueryMessageResponseProtocol: SQLQueryMessageResponseProtocol, ~Copyable {
    associatedtype DataRowMessage: PostgresDataRowMessageProtocol
    associatedtype RowDescriptionMessage: PostgresRowDescriptionMessageProtocol

    static func parse(
        logger: Logger,
        msg: PostgresRawMessage
    ) throws -> Self

    func readUntilReadyForQuery(
        on connection: inout some PostgresConnectionProtocol & ~Copyable,
        _ onMessage: (PostgresRawMessage) throws -> Void
    ) async throws

    func asDataRow() -> DataRowMessage?
    func asRowDescription() -> RowDescriptionMessage?
}