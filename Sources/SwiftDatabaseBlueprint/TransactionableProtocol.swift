
public protocol TransactionableProtocol: Sendable {
    associatedtype Transaction: DatabaseTransactionProtocol

    // archive?
    static func create(on transaction: Transaction) async throws
    static func delete(soft: Bool, on transaction: Transaction) async throws
    static func restore(on transaction: Transaction) async throws
    static func update(on transaction: Transaction) async throws
}