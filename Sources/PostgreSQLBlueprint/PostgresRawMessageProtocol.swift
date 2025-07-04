
import Logging
import SQLBlueprint
import SwiftDatabaseBlueprint

public protocol PostgresRawMessageProtocol: SQLRawMessageProtocol, ~Copyable {
    static func read<T: PostgresConnectionProtocol>(
        on connection: borrowing T
    ) async throws -> Self
}