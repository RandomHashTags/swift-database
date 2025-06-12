
public protocol DatabaseTransaction: Sendable {
    associatedtype IDValue: Codable & Hashable & Sendable
    
    var id: IDValue { get }
}