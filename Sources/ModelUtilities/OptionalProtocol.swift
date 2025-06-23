
public protocol OptionalProtocol: ~Copyable {
    associatedtype Wrapped

    init(_ value: consuming Wrapped)

    func value() -> Wrapped?
}

extension Optional: OptionalProtocol {
    @inlinable
    public func value() -> Wrapped? {
        switch self {
        case .none: nil
        case .some(let v): v
        }
    }
}