
import SQL
import SwiftDatabase

public protocol PostgresDatabase: SQLDatabase where Command == PostgresCommand {
}