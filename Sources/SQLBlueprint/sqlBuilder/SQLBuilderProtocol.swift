
public protocol SQLBuilderProtocol: Sendable {

    /// - Returns: An unsafe SQL query.
    mutating func build() -> String
}