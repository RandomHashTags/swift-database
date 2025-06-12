
import SwiftDatabase

public protocol SQLCommand: DatabaseCommand {
    var sqlValue: String { get }
}