
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

    @inlinable
    public var logger: Logger {
        connection.logger
    }
}

// MARK: Begin
extension PostgresTransaction {
    @discardableResult
    @inlinable
    mutating func begin() async throws -> QueryMessage.ConcreteResponse {
        return try await query(unsafeSQL: "BEGIN", { _ in })
    }
}

// MARK: Commit
extension PostgresTransaction {
    @discardableResult
    @inlinable
    mutating func commit() async throws -> QueryMessage.ConcreteResponse {
        return try await query(unsafeSQL: "COMMIT", { _ in })
    }
}

// MARK: Query
extension PostgresTransaction {
    @discardableResult
    @inlinable
    public mutating func query(
        unsafeSQL: String,
        _ onMessage: (RawMessage) throws -> Void
    ) async throws -> QueryMessage.ConcreteResponse {
        return try await connection.query(unsafeSQL: unsafeSQL, onMessage)
    }
}

// MARK: Rollback
extension PostgresTransaction {
    @discardableResult
    @inlinable
    mutating func rollback() async throws -> QueryMessage.ConcreteResponse {
        return try await query(unsafeSQL: "ROLLBACK", { _ in })
    }

    @discardableResult
    @inlinable
    public mutating func rollbackTo<T: StringProtocol>(savepoint: T) async throws -> QueryMessage.ConcreteResponse {
        return try await query(unsafeSQL: "ROLLBACK TO " + savepoint, { _ in })
    }
}

// MARK: Savepoint
extension PostgresTransaction {
    @discardableResult
    @inlinable
    public mutating func savepoint<T: StringProtocol>(named: T) async throws -> QueryMessage.ConcreteResponse {
        return try await query(unsafeSQL: "SAVEPOINT " + named, { _ in })
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