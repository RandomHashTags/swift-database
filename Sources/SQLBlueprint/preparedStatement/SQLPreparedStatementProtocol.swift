
public protocol SQLPreparedStatementProtocol: Sendable, ~Copyable {
    @inlinable
    func prepare<T: SQLConnectionProtocol & ~Copyable>(
        on connection: borrowing T
    ) async throws -> T.QueryMessage.ConcreteResponse
}