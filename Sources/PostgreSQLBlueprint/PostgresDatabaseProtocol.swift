
import SQL
import SwiftDatabase

public protocol PostgresDatabaseProtocol: SQLDatabaseProtocol where Command == PostgresCommand {
}