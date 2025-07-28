
public protocol PostgresSQLBuilderComponent: Sendable, ~Copyable {
    var sql: String { get }
}