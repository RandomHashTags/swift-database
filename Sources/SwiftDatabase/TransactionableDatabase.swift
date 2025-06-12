
public protocol TransactionableDatabase: Database {
    associatedtype Transaction: DatabaseTransaction

    @discardableResult
    func transaction<V>(_ work: (borrowing Transaction) async throws -> V) async rethrows -> V
}