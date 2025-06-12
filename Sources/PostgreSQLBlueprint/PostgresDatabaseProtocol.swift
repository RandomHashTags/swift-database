
import SQLBlueprint
import SwiftDatabaseBlueprint

public protocol PostgresDatabaseProtocol: SQLDatabaseProtocol where Command: PostgresCommandProtocol {
}