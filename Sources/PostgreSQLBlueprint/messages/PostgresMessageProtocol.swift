
import SQLBlueprint

public protocol PostgresMessageProtocol: Sendable, ~Copyable {
    @inlinable
    mutating func write<Connection: PostgresConnectionProtocol & ~Copyable>(to connection: borrowing Connection) throws
}