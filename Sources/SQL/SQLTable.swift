
public protocol SQLTable: Sendable {
    associatedtype Record: SQLRecord

    static var schema: String { get }
}