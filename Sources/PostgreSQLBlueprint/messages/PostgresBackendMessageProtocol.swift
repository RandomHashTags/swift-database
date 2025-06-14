
public protocol PostgresBackendMessageProtocol: PostgresMessageProtocol, ~Copyable {
    static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws
}