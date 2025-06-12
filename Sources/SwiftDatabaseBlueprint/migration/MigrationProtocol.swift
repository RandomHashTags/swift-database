
public protocol MigrationProtocol: Sendable {
    associatedtype DBVersion: DatabaseVersionProtocol

    static var schema: String { get }

    var id: DBVersion { get }
    var name: String? { get }

    func migrate(on database: any DatabaseProtocol, asTransaction: Bool) async throws
    func revert(on database: any DatabaseProtocol, asTransaction: Bool) async throws
}