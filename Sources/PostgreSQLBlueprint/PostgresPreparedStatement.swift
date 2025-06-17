
import SQLBlueprint

public struct PostgresPreparedStatement<each Value: SQLDataTypeProtocol>: SQLPreparedStatementProtocol {
    public let name:String
    public let prepareSQL:String

    // Crashes compiler | https://github.com/swiftlang/swift/issues/82164#issuecomment-2981507249
    /*@inlinable
    public init<let fieldDataTypesCount: Int>(
        name: String,
        sql: String
    ) {
        self.name = name
        self.prepareSQL = sql
    }*/

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