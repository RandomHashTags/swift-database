
import SQLBlueprint

public protocol PostgresTransactionProtocol: SQLTransactionProtocol, ~Copyable where Connection: PostgresConnectionProtocol {
}