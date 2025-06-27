
public protocol PostgresRowDescriptionMessageProtocol: PostgresBackendMessageProtocol, ~Copyable {
    @inlinable
    func decode<Queryable: PostgresQueryableProtocol & ~Copyable, T: PostgresDataRowDecodable>(
        on queryable: inout Queryable,
        as decodable: T.Type
    ) async throws -> [T?]
}