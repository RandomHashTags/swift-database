
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

public final class PostgresDatabase: PostgresDatabaseProtocol {
    public typealias Command = PostgresCommand

    public let address: String
    public let port: Int
    public let username: String
    public let password: String?
    public let storageMethod: DatabaseStorageMethod

    public init(
        address: String,
        port: Int,
        username: String,
        password: String?,
        storageMethod: DatabaseStorageMethod = .device
    ) {
        self.address = address
        self.port = port
        self.username = username
        self.password = password
        self.storageMethod = storageMethod
    }
}

// MARK: Execute
extension PostgresDatabase {
    @inlinable
    public func execute(_ command: Command) async throws {
    }
}

// MARK: Connect
extension PostgresDatabase {
    @inlinable
    public func connect() async throws {
    }
}

// MARK: Disconnect
extension PostgresDatabase {
    @inlinable
    public func disconnect() throws {
    }
}