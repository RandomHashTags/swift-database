
import SwiftDatabaseBlueprint

public protocol SQLCommandProtocol: DatabaseCommandProtocol {
    var sqlValue: String { get }
}