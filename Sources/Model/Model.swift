
public protocol Model: AnyModel {
    associatedtype IDValue: Codable, Sendable
    var id: IDValue? { get set }
}

extension Model {
    @inlinable
    public func requireID() throws -> IDValue {
        guard let id else {
            throw ModelError.idRequired("\(Self.self) `id` found to be nil")
        }
        return id
    }
}