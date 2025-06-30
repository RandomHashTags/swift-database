
public protocol RawModelIdentifier {
    var rawValue: String { get }
}

extension String: RawModelIdentifier {
    public var rawValue: String { self }
}
extension Substring: RawModelIdentifier {
    public var rawValue: String { String(self) }
}
extension AnyKeyPath: RawModelIdentifier {
    public var rawValue: String { debugDescription }
}