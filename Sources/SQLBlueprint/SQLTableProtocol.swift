
public protocol SQLTableProtocol: Sendable {
    associatedtype Record: SQLRecordProtocol

    var schema: String { get }
}