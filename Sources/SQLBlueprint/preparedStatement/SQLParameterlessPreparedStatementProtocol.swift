
public protocol SQLParameterlessPreparedStatementProtocol: SQLPreparedStatementProtocol, ~Copyable {
    func execute<T: SQLQueryableProtocol & ~Copyable>(
        on queryable: borrowing T,
        explain: Bool,
        analyze: Bool
    ) async throws -> T.QueryMessage.ConcreteResponse
}

// MARK: Convenience
extension SQLConnectionProtocol {
    @inlinable
    public func executePreparedStatement<T: SQLParameterlessPreparedStatementProtocol & ~Copyable>(
        _ statement: borrowing T,
        explain: Bool = false,
        analyze: Bool = false
    ) async throws -> QueryMessage.ConcreteResponse {
        return try await statement.execute(on: self, explain: explain, analyze: analyze)
    }
}