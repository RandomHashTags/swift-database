
public protocol SQLTableProtocol: Sendable {
    associatedtype Record: SQLRecordProtocol

    static var schema: String { get }
}