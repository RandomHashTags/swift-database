
public protocol SQLTransactionProtocol: Sendable, ~Copyable {
    associatedtype Connection: SQLConnectionProtocol

    func query(unsafeSQL: String) async throws -> Connection.QueryMessage.ConcreteResponse
}