
import SwiftDatabase

public protocol SQLDatabase: RelationalDatabase, TransactionableDatabase {
    associatedtype Table: SQLTable
}