
public protocol PostgresFrontendMessageProtocol: PostgresMessageProtocol, ~Copyable {
    @inlinable
    mutating func write<Connection: PostgresConnectionProtocol & ~Copyable>(
        to connection: borrowing Connection
    ) async throws
}