
public protocol SQLQueryMessageResponseProtocol: Sendable, ~Copyable {
    func requireNotError() throws -> Self
}