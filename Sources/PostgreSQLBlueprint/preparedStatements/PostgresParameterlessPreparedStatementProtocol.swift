
import SQLBlueprint

public protocol PostgresParameterlessPreparedStatementProtocol: SQLParameterlessPreparedStatementProtocol, PostgresPreparedStatementProtocol, ~Copyable {
    func execute<T: PostgresQueryableProtocol & ~Copyable>(
        on queryable: inout T,
        explain: Bool,
        analyze: Bool
    ) async throws -> T.QueryMessage.ConcreteResponse
}

// MARK: Convenience
extension PostgresConnectionProtocol {
    @inlinable
    public mutating func executePreparedStatement(
        _ statement: inout some PostgresParameterlessPreparedStatementProtocol & ~Copyable,
        explain: Bool = false,
        analyze: Bool = false
    ) async throws -> QueryMessage.ConcreteResponse {
        return try await statement.execute(on: &self, explain: explain, analyze: analyze)
    }
}