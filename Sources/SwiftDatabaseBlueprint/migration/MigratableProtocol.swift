
public protocol MigratableProtocol: Sendable {
    associatedtype DBVersion: DatabaseVersionProtocol
    associatedtype DBCommand: DatabaseCommandProtocol

    static var schema: String { get }
    static var migrations: [DBVersion: [DBCommand]] { get }
}