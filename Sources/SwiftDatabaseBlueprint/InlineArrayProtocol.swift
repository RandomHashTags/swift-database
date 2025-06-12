
public protocol InlineArrayProtocol {
    associatedtype Element

    var count: Int { get }
}


extension InlineArray: InlineArrayProtocol {
}