
import SQLBlueprint

public struct PostgresPreparedStatement<each Value: SQLDataTypeProtocol>: Sendable {
    public let name:String
    public let prepareSQL:String

    @inlinable
    public init(
        name: String,
        fieldDataTypes: [String],
        sql: String
    ) {
        self.name = name
        prepareSQL = "PREPARE \(name) (\(fieldDataTypes.joined(separator: ", "))) AS \(sql);"
    }
}


extension PostgresError {
    static let test:PostgresPreparedStatement<String, String, Int> = PostgresPreparedStatement(name: "", fieldDataTypes: [], sql: "")
}
// MARK: Prepare
extension PostgresPreparedStatement {
    @inlinable
    public func prepare<T: PostgresConnectionProtocol & ~Copyable>(
        on connection: borrowing T
    ) async throws -> T.QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: prepareSQL)
    }
}

// MARK: Execute
extension PostgresPreparedStatement {
    @inlinable
    public func execute<T: PostgresConnectionProtocol & ~Copyable>(
        on connection: borrowing T,
        values: (repeat each Value),
        explain: Bool = false,
        analyze: Bool = false
    ) async throws -> T.QueryMessage.ConcreteResponse {
        let sql = (explain ? "EXPLAIN " : "") + (analyze ? "ANALYZE " : "") + "EXECUTE \(name)("
        var valueString = ""
        for value in repeat each values {
            valueString += "\(value), "
        }
        if !valueString.isEmpty {
            valueString.removeLast(2)
        }
        return try await connection.query(unsafeSQL: sql + valueString + ");")
    }
}