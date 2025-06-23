
import Logging
import PostgreSQLBlueprint
import SQLBlueprint

public struct PostgresTransaction: PostgresTransactionProtocol, ~Copyable {
    public typealias QueryMessage = PostgresQueryMessage

    @usableFromInline
    var connection:PostgresConnection

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
    mutating func begin() async throws -> QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: "BEGIN")
    }
}

// MARK: Commit
extension PostgresTransaction {
    @discardableResult
    @inlinable
    mutating func commit() async throws -> QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: "COMMIT")
    }
}

// MARK: Query
extension PostgresTransaction {
    @discardableResult
    @inlinable
    public mutating func query(unsafeSQL: String) async throws -> QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: unsafeSQL)
    }
}

// MARK: Rollback
extension PostgresTransaction {
    @discardableResult
    @inlinable
    mutating func rollback() async throws -> QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: "ROLLBACK")
    }

    @discardableResult
    @inlinable
    public mutating func rollbackTo<T: StringProtocol>(savepoint: T) async throws -> QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: "ROLLBACK TO " + savepoint)
    }
}

// MARK: Savepoint
extension PostgresTransaction {
    @discardableResult
    @inlinable
    public mutating func savepoint<T: StringProtocol>(named: T) async throws -> QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: "SAVEPOINT " + named)
    }
}

// MARK: Convenience
extension PostgresTransaction {
    @discardableResult
    @inlinable
    public mutating func rollbackTo<T: RawRepresentable>(savepoint: T) async throws -> QueryMessage.ConcreteResponse where T.RawValue: StringProtocol {
        return try await rollbackTo(savepoint: savepoint.rawValue)
    }

    @discardableResult
    @inlinable
    public mutating func savepoint<T: RawRepresentable>(named: T) async throws -> QueryMessage.ConcreteResponse where T.RawValue: StringProtocol {
        return try await savepoint(named: named.rawValue)
    }
}

extension PostgresConnection {
    @discardableResult
    @inlinable
    public func transaction<T>(_ work: (inout PostgresTransaction) async throws -> T) async throws -> T {
        var transaction = PostgresTransaction(connection: self)
        try await transaction.begin().requireNotError()
        do {
            let result = try await work(&transaction)
            try await transaction.commit().requireNotError()
            return result
        } catch {
            do {
                try await transaction.rollback().requireNotError()
            } catch {
                logger.error("encountered error trying to rollback transaction: \(error)")
            }
            throw error
        }
    }
}