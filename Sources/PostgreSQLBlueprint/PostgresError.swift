
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

// MARK: Connection failure
extension PostgresError {
    @inlinable public static func connectionFailure(_ reason: String = "") -> PostgresError { PostgresError(identifier: "connectionFailure", reason: reason) }
}

// MARK: Socket failure
extension PostgresError {
    @inlinable public static func socketFailure(_ reason: String = "") -> PostgresError { PostgresError(identifier: "socketFailure", reason: reason) }
}










// MARK: Messages










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

// MARK: Empty query response
extension PostgresError {
    @inlinable public static func emptyQueryResponse(_ reason: String = "") -> PostgresError { PostgresError(identifier: "emptyQueryResponseError", reason: reason) }
}

// MARK: Error response
extension PostgresError {
    @inlinable public static func errorResponse(_ reason: String = "") -> PostgresError { PostgresError(identifier: "errorResponseError", reason: reason) }
}

// MARK: Function call response
extension PostgresError {
    @inlinable public static func functionCallResponse(_ reason: String = "") -> PostgresError { PostgresError(identifier: "functionCallResponseError", reason: reason) }
}

// MARK: Notice response
extension PostgresError {
    @inlinable public static func noticeResponse(_ reason: String = "") -> PostgresError { PostgresError(identifier: "noticeResponseError", reason: reason) }
}

// MARK: No data
extension PostgresError {
    @inlinable public static func noData(_ reason: String = "") -> PostgresError { PostgresError(identifier: "noDataError", reason: reason) }
}

// MARK: Notification response
extension PostgresError {
    @inlinable public static func notificationResponse(_ reason: String = "") -> PostgresError { PostgresError(identifier: "notificationResponseError", reason: reason) }
}

// MARK: Parameter description
extension PostgresError {
    @inlinable public static func parameterDescription(_ reason: String = "") -> PostgresError { PostgresError(identifier: "parameterDescriptionError", reason: reason) }
}

// MARK: Parameter status
extension PostgresError {
    @inlinable public static func parameterStatus(_ reason: String = "") -> PostgresError { PostgresError(identifier: "parameterStatusError", reason: reason) }
}

// MARK: Parse complete
extension PostgresError {
    @inlinable public static func parseComplete(_ reason: String = "") -> PostgresError { PostgresError(identifier: "parseCompleteError", reason: reason) }
}

// MARK: Portal suspended
extension PostgresError {
    @inlinable public static func portalSuspended(_ reason: String = "") -> PostgresError { PostgresError(identifier: "portalSuspendedError", reason: reason) }
}

// MARK: Ready for query
extension PostgresError {
    @inlinable public static func readyForQuery(_ reason: String = "") -> PostgresError { PostgresError(identifier: "readyForQueryError", reason: reason) }
}

// MARK: Row description
extension PostgresError {
    @inlinable public static func rowDescription(_ reason: String = "") -> PostgresError { PostgresError(identifier: "rowDescriptionError", reason: reason) }
}