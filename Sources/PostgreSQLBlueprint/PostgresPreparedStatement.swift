
import SQLBlueprint

public struct PostgresPreparedStatement<each Value: SQLDataTypeProtocol>: Sendable {
    public let name:String
    public let prepareSQL:String

    // Crashes compiler
    /*@inlinable
    public init<let fieldDataTypesCount: Int>(
        name: String,
        fieldDataTypes: InlineArray<fieldDataTypesCount, String>,
        sql: String
    ) {
        self.name = name
        var prepareSQL = "PREPARE \(name) ("
        if fieldDataTypesCount > 0 {
            var i = 0
            let oneBeforeLast = fieldDataTypesCount - 1
            while i < oneBeforeLast {
                prepareSQL += ", " + fieldDataTypes[i]
                i += 1
            }
            prepareSQL += (i == 0 ? "" : ", ") + fieldDataTypes[i]
        }
        prepareSQL += ") AS \(sql);"
        self.prepareSQL = prepareSQL
    }*/

    @inlinable
    public init(
        name: String,
        fieldDataTypes: [String],
        sql: String
    ) {
        self.name = name
        var prepareSQL = "PREPARE \(name) ("
        let fieldDataTypesCount = fieldDataTypes.count
        if fieldDataTypesCount > 0 {
            var i = 0
            let oneBeforeLast = fieldDataTypesCount - 1
            while i < oneBeforeLast {
                prepareSQL += ", " + fieldDataTypes[i]
                i += 1
            }
            prepareSQL += (i == 0 ? "" : ", ") + fieldDataTypes[i]
        }
        prepareSQL += ") AS \(sql);"
        self.prepareSQL = prepareSQL
    }
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