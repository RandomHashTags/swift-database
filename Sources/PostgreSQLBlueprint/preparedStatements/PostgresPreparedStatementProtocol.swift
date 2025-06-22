
import SQLBlueprint

public protocol PostgresPreparedStatementProtocol: SQLPreparedStatementProtocol, ~Copyable {
    @inlinable
    func prepare<T: PostgresQueryableProtocol & ~Copyable>(
        on connection: inout T
    ) async throws -> T.QueryMessage.ConcreteResponse
}