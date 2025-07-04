
import SQLBlueprint

public protocol PostgresTransactionProtocol: SQLTransactionProtocol, ~Copyable where QueryMessage: PostgresQueryMessageProtocol {
}