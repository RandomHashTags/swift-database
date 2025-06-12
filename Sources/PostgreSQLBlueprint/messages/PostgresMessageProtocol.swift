
import SQLBlueprint

public protocol PostgresMessageProtocol: Sendable {
    @inlinable
    mutating func write<Connection: PostgresConnectionProtocol & ~Copyable>(to connection: borrowing Connection) throws
}