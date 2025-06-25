
import ModelUtilities

public protocol PostgresDataDecodable: Sendable, ~Copyable {
    static func postgresDecode(
        as type: PostgresDataType,
        _ value: String
    ) throws -> Self?
}