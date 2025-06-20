
import Logging
import PostgreSQLBlueprint
import SQLBlueprint

public struct PostgresTransaction: PostgresTransactionProtocol, ~Copyable {
    public typealias Connection = PostgresConnection

    @usableFromInline
    let connection:PostgresConnection

    @inlinable
    public init(
        connection: PostgresConnection
    ) {
        self.connection = connection
    }
}

// MARK: Begin
extension PostgresTransaction {
    @discardableResult
    @inlinable
    func begin() async throws -> PostgresConnection.QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: "BEGIN")
    }
}

// MARK: Commit
extension PostgresTransaction {
    @discardableResult
    @inlinable
    func commit() async throws -> PostgresConnection.QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: "COMMIT")
    }
}

// MARK: Query
extension PostgresTransaction {
    @discardableResult
    @inlinable
    public func query(unsafeSQL: String) async throws -> PostgresConnection.QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: unsafeSQL)
    }
}

// MARK: Rollback
extension PostgresTransaction {
    @discardableResult
    @inlinable
    func rollback() async throws -> PostgresConnection.QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: "ROLLBACK")
    }

    @discardableResult
    @inlinable
    public func rollbackTo(savepoint: String) async throws -> PostgresConnection.QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: "ROLLBACK TO " + savepoint)
    }
}

// MARK: Savepoint
extension PostgresTransaction {
    @discardableResult
    @inlinable
    public func savepoint(named: String) async throws -> PostgresConnection.QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: "SAVEPOINT " + named)
    }
}

// MARK: Convenience
extension PostgresConnection {
    @inlinable
    public func transaction(_ work: (inout PostgresTransaction) async throws -> Void) async throws {
        var transaction = PostgresTransaction(connection: self)
        try await transaction.begin()
        do {
            try await work(&transaction)
            try await transaction.commit()
        } catch {
            do {
                try await transaction.rollback()
            } catch {
                logger.error("encountered error trying to rollback transaction: \(error)")
            }
            throw error
        }
    }
}