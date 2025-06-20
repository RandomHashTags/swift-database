
import SQLBlueprint

public struct PostgresPreparedStatement<each Parameter: SQLDataTypeProtocol>: SQLParameterizedPreparedStatementProtocol {
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
    public func prepare<T: SQLConnectionProtocol & ~Copyable>(
        on connection: borrowing T
    ) async throws -> T.QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: prepareSQL)
    }
}

// MARK: Execute
extension PostgresPreparedStatement {
    /*
    public func execute<each Parameter, T: SQLConnectionProtocol & ~Copyable>(
        on connection: borrowing T,
        parameters: (repeat each Parameter),
        explain: Bool,
        analyze: Bool
    ) async throws -> T.QueryMessage.ConcreteResponse {
        let sql = (explain ? "EXPLAIN " : "") + (analyze ? "ANALYZE " : "") + "EXECUTE \(name)("
        var valueString = ""
        for param in repeat each parameters {
            valueString += "\(param), "
        }
        if !valueString.isEmpty {
            valueString.removeLast(2)
        }
        return try await connection.query(unsafeSQL: sql + valueString + ");")
    }*/

    @inlinable
    func parameterSQL(_ parameters: (repeat each Parameter)) -> String {
        var valueString = ""
        var added = false
        for param in repeat each parameters {
            valueString += "\(param), "
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
    public func execute<T: PostgresConnectionProtocol & ~Copyable>(
        on connection: borrowing T,
        parameters: (repeat each Parameter),
        explain: Bool = false,
        analyze: Bool = false
    ) async throws -> T.QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: executionSQL(parameters: (repeat each parameters), explain: explain, analyze: analyze))
    }

    @inlinable
    public func execute<T: PostgresTransactionProtocol & ~Copyable>(
        on transaction: borrowing T,
        parameters: (repeat each Parameter),
        explain: Bool = false,
        analyze: Bool = false
    ) async throws -> T.Connection.QueryMessage.ConcreteResponse {
        return try await transaction.query(unsafeSQL: executionSQL(parameters: (repeat each parameters), explain: explain, analyze: analyze))
    }
}