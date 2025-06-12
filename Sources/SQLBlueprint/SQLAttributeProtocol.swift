
import SwiftDatabase

public protocol SQLAttributeProtocol: Sendable {
    associatedtype DataType: DatabaseDataTypeProtocol
    
    /// The name of this attribute as diplayed in the database.
    var name: String { get }

    /// How this attribute is represented in the database.
    var dataType: DataType { get }
}