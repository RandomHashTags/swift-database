
import Models

public protocol PostgresModel: Model, ~Copyable, PostgresDataRowDecodable {
    mutating func create<T: PostgresQueryableProtocol & ~Copyable>(
        on queryable: inout T,
        explain: Bool,
        analyze: Bool
    ) async throws -> Self

    mutating func update<T: PostgresQueryableProtocol & ~Copyable>(
        on queryable: inout T,
        explain: Bool,
        analyze: Bool
    ) async throws -> Self
}