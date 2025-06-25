
import ModelUtilities

public protocol PostgresDataDecodable: Sendable, ~Copyable {
    static func postgresDecode(
        _ value: String,
        as type: PostgresDataType
    ) throws -> Self?
}