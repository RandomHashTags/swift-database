
public struct PostgresError: Error {
    public let identifier:String
    public let reason:String

    public init(identifier: String, reason: String) {
        self.identifier = identifier
        self.reason = reason
    }
}

// MARK: Read message
extension PostgresError {
    @inlinable public static func readMessage(_ reason: String = "") -> PostgresError { PostgresError(identifier: "readMessageError", reason: reason) }
}

// MARK: Authentication
extension PostgresError {
    @inlinable public static func authentication(_ reason: String = "") -> PostgresError { PostgresError(identifier: "authenticationError", reason: reason) }
}

// MARK: Connection already established
extension PostgresError {
    @inlinable public static func connectionAlreadyEstablished(_ reason: String = "") -> PostgresError { PostgresError(identifier: "connectionAlreadyEstablished", reason: reason) }
}