
public protocol PostgresRowDescriptionMessageProtocol: PostgresBackendMessageProtocol, ~Copyable {
    @inlinable
    func decode<T: PostgresDataRowDecodable, Connection: PostgresConnectionProtocol & ~Copyable>(
        on connection: inout Connection,
        as decodable: T.Type
    ) throws -> [T?]
}