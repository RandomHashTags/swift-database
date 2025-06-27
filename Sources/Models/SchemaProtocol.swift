
public protocol SchemaProtocol: Sendable, ~Copyable {
    static var schema: String { get }
    static var alias: String? { get }
}