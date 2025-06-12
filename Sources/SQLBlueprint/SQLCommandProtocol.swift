
import SwiftDatabase

public protocol SQLCommandProtocol: DatabaseCommandProtocol {
    var sqlValue: String { get }
}