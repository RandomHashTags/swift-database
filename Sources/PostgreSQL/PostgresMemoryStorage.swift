
import Logging
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

public struct PostgresMemoryStorage: PostgresQueryableProtocol {
    public typealias QueryMessage = PostgresQueryMessage

    public let logger:Logger

    private var responseQueue:[PostgresQueryMessage.Response] = []

    public init() {
        logger = Logger(label: "database.swift.postgresMemoryStorage")
    }
}

// MARK: Read until RFQ
extension PostgresMemoryStorage {
    public mutating func readUntilReadyForQuery(_ onMessage: (PostgresRawMessage) throws -> Void) async throws {
        guard !responseQueue.isEmpty else { return }
        let msg = responseQueue.removeFirst()
        try await msg.readUntilReadyForQuery(on: &self, onMessage)
    }
}

// MARK: Query
extension PostgresMemoryStorage {
    public mutating func query(unsafeSQL: String, _ onMessage: (PostgresRawMessage) throws -> Void) async throws -> PostgresQueryMessage.Response {
        return .readyForQuery(.init(transactionStatus: .idle))
        // TODO: finish
    }
}