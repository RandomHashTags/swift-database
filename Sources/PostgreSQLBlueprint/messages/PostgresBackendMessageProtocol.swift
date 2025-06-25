
public protocol PostgresBackendMessageProtocol: PostgresMessageProtocol, ~Copyable {
    static func parse(
        message: PostgresRawMessage
    ) throws -> Self
}