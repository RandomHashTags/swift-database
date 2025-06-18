
public protocol SQLParameterlessPreparedStatementProtocol: SQLPreparedStatementProtocol, ~Copyable {
    func execute<T: SQLConnectionProtocol & ~Copyable>(
        on connection: borrowing T,
        explain: Bool,
        analyze: Bool
    ) async throws -> T.QueryMessage.ConcreteResponse
}