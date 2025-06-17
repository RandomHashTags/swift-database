
public protocol PostgresSQLBuilderComponent: Sendable {
    var sql: String { get }
}