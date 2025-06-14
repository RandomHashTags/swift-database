
public protocol DatabaseTransactionProtocol: Sendable {
    associatedtype IDValue: Codable & Hashable & Sendable
    
    var id: IDValue { get }
    //
}