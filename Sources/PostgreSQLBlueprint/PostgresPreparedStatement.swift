
import SQLBlueprint

public struct PostgresPreparedStatement<each Parameter: PostgresDataTypeProtocol>: SQLParameterizedPreparedStatementProtocol {
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
extension PostgresPreparedStatement {
    @inlinable
    public func prepare<T: SQLQueryableProtocol & ~Copyable>(
        on connection: borrowing T
    ) async throws -> T.QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: prepareSQL)
    }
}

// MARK: Execute
extension PostgresPreparedStatement {
    @inlinable
    func parameterSQL(_ parameters: (repeat each Parameter)) -> String {
        var valueString = ""
        var added = false
        for param in repeat each parameters {
            valueString += param.postgresValue + ", "
            added = true
        }
        if added {
            valueString.removeLast(2)
        }
        return valueString
    }

    @inlinable
    func executionSQL(
        parameters: (repeat each Parameter),
        explain: Bool,
        analyze: Bool
    ) -> String {
        var sql = (explain ? "EXPLAIN " : "") + (analyze ? "ANALYZE " : "") + "EXECUTE \(name)("
        sql += parameterSQL((repeat each parameters))
        return sql + ");"
    }

    @inlinable
    public func execute<T: SQLQueryableProtocol & ~Copyable>(
        on queryable: borrowing T,
        parameters: (repeat each Parameter),
        explain: Bool = false,
        analyze: Bool = false
    ) async throws -> T.QueryMessage.ConcreteResponse {
        return try await queryable.query(unsafeSQL: executionSQL(parameters: (repeat each parameters), explain: explain, analyze: analyze))
    }
}