
import Models

public protocol PostgresModel: Model, ~Copyable, PostgresDataRowDecodable {
    mutating func create(
        on queryable: inout some PostgresQueryableProtocol & ~Copyable,
        explain: Bool,
        analyze: Bool
    ) async throws -> Self

    mutating func update(
        on queryable: inout some PostgresQueryableProtocol & ~Copyable,
        explain: Bool,
        analyze: Bool
    ) async throws -> Self
}