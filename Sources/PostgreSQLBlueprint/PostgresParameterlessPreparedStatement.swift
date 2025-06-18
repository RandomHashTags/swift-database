
import SQLBlueprint

public struct PostgresParameterlessPreparedStatement: SQLParameterlessPreparedStatementProtocol {
    public let name:String
    public let prepareSQL:String

    @inlinable
    public init(
        name: String,
        sql: String
    ) {
        self.name = name
        self.prepareSQL = sql
    }
}

// MARK: Prepare
extension PostgresParameterlessPreparedStatement {
    @inlinable
    public func prepare<T: SQLConnectionProtocol & ~Copyable>(
        on connection: borrowing T
    ) async throws -> T.QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: prepareSQL)
    }
}

// MARK: Execute
extension PostgresParameterlessPreparedStatement {
    @inlinable
    public func execute<T: SQLConnectionProtocol & ~Copyable>(
        on connection: borrowing T,
        explain: Bool = false,
        analyze: Bool = false
    ) async throws -> T.QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: (explain ? "EXPLAIN " : "") + (analyze ? "ANALYZE " : "") + "EXECUTE \(name);")
    }
}