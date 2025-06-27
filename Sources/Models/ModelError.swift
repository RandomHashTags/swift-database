
public struct ModelError: Error {
    public let identifier:String
    public let reason:String

    public init(identifier: String, reason: String) {
        self.identifier = identifier
        self.reason = reason
    }
}

// MARK: Error
extension ModelError {
    @inlinable public static func error(_ reason: String = "") -> ModelError { ModelError(identifier: "modelError", reason: reason) }
}

// MARK: Id required
extension ModelError {
    @inlinable public static func idRequired(_ reason: String = "") -> ModelError { ModelError(identifier: "idRequired", reason: reason) }
}