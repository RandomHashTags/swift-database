
public protocol InlineArrayProtocol: Sendable, ~Copyable {
    associatedtype Element

    var count: Int { get }
}

extension InlineArray: InlineArrayProtocol {
}