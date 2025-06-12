
public protocol DatabaseProtocol: Sendable {
    associatedtype Command: DatabaseCommandProtocol

    /// The address of the database we want to connect to.
    var address: String { get }

    /// The username of the user that controls the database we want to access.
    var username: String { get }

    /// The password to the database we want to access.
    var password: String? { get }

    /// How this database is stored.
    var storageMethod: DatabaseStorageMethod { get }

    /// Executes a command on the database.
    func execute(_ command: Command) async throws
}