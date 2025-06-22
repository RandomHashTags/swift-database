
public protocol SQLPreparedStatementProtocol: Sendable, ~Copyable {
    @inlinable
    func prepare<T: SQLQueryableProtocol & ~Copyable>(
        on connection: borrowing T
    ) async throws -> T.QueryMessage.ConcreteResponse
}