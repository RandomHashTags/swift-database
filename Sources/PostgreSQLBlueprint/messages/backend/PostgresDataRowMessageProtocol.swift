
public protocol PostgresDataRowMessageProtocol: PostgresBackendMessageProtocol, ~Copyable {
    func decode<T: PostgresDataRowDecodable>(
        as decodable: T.Type
    ) throws -> T?
}