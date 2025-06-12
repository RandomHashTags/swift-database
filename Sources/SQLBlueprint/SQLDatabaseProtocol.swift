
import SwiftDatabaseBlueprint

public protocol SQLDatabaseProtocol: RelationalDatabaseProtocol, TransactionableDatabaseProtocol {
    //associatedtype Table: SQLTableProtocol
}