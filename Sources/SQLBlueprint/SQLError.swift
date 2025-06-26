
public struct SQLError: Error {
    public let identifier:String
    public let reason:String

    public init(identifier: String, reason: String) {
        self.identifier = identifier
        self.reason = reason
    }
}

// MARK: Receive
extension SQLError {
    @inlinable public static func receive(reason: String = "") -> SQLError { SQLError(identifier: "receiveError", reason: reason) }
}

// MARK: Send
extension SQLError {
    @inlinable public static func send(reason: String = "") -> SQLError { SQLError(identifier: "sendError", reason: reason) }
}