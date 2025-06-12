
import SwiftDatabase

public protocol SQLDatabaseProtocol: RelationalDatabaseProtocol, TransactionableDatabaseProtocol {
    associatedtype Table: SQLTableProtocol
}