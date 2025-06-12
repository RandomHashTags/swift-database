
import SwiftDatabase

public protocol SQLAttribute: Sendable {
    associatedtype DataType: DatabaseDataType
    
    /// The name of this attribute as diplayed in the database.
    var name: String { get }

    /// How this attribute is represented in the database.
    var dataType: DataType { get }
}