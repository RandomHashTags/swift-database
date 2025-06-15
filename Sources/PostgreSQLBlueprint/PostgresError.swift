
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

// MARK: Malformed data
extension PostgresError {
    @inlinable public static func malformedData(_ reason: String = "") -> PostgresError { PostgresError(identifier: "malformedData", reason: reason) }
}

// MARK: Connection already established
extension PostgresError {
    @inlinable public static func connectionAlreadyEstablished(_ reason: String = "") -> PostgresError { PostgresError(identifier: "connectionAlreadyEstablished", reason: reason) }
}

// MARK: Authentication
extension PostgresError {
    @inlinable public static func authentication(_ reason: String = "") -> PostgresError { PostgresError(identifier: "authenticationError", reason: reason) }
}

// MARK: BackendKeyData
extension PostgresError {
    @inlinable public static func backendKeyData(_ reason: String = "") -> PostgresError { PostgresError(identifier: "backendKeyDataError", reason: reason) }
}

// MARK: Bind complete
extension PostgresError {
    @inlinable public static func bindComplete(_ reason: String = "") -> PostgresError { PostgresError(identifier: "bindCompleteError", reason: reason) }
}

// MARK: Close complete
extension PostgresError {
    @inlinable public static func closeComplete(_ reason: String = "") -> PostgresError { PostgresError(identifier: "closeCompleteError", reason: reason) }
}

// MARK: Command complete
extension PostgresError {
    @inlinable public static func commandComplete(_ reason: String = "") -> PostgresError { PostgresError(identifier: "commandCompleteError", reason: reason) }
}

// MARK: Copy data
extension PostgresError {
    @inlinable public static func copyData(_ reason: String = "") -> PostgresError { PostgresError(identifier: "copyDataError", reason: reason) }
}

// MARK: Copy done
extension PostgresError {
    @inlinable public static func copyDone(_ reason: String = "") -> PostgresError { PostgresError(identifier: "copyDoneError", reason: reason) }
}

// MARK: Copy in response
extension PostgresError {
    @inlinable public static func copyInResponse(_ reason: String = "") -> PostgresError { PostgresError(identifier: "copyInResponseError", reason: reason) }
}

// MARK: Copy out response
extension PostgresError {
    @inlinable public static func copyOutResponse(_ reason: String = "") -> PostgresError { PostgresError(identifier: "copyOutResponseError", reason: reason) }
}

// MARK: Copy both response
extension PostgresError {
    @inlinable public static func copyBothResponse(_ reason: String = "") -> PostgresError { PostgresError(identifier: "copyBothResponseError", reason: reason) }
}

// MARK: Data row
extension PostgresError {
    @inlinable public static func dataRow(_ reason: String = "") -> PostgresError { PostgresError(identifier: "dataRowError", reason: reason) }
}

// MARK: Error response
extension PostgresError {
    @inlinable public static func errorResponse(_ reason: String = "") -> PostgresError { PostgresError(identifier: "errorResponseError", reason: reason) }
}

// MARK: Notice response
extension PostgresError {
    @inlinable public static func noticeResponse(_ reason: String = "") -> PostgresError { PostgresError(identifier: "noticeResponseError", reason: reason) }
}

// MARK: Ready for query
extension PostgresError {
    @inlinable public static func readyForQuery(_ reason: String = "") -> PostgresError { PostgresError(identifier: "readyForQueryError", reason: reason) }
}