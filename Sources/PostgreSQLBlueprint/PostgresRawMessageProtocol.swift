
import Logging
import SQLBlueprint
import SwiftDatabaseBlueprint

public protocol PostgresRawMessageProtocol: SQLRawMessageProtocol, ~Copyable {
    static func read(
        on connection: borrowing some PostgresConnectionProtocol
    ) async throws -> Self
}