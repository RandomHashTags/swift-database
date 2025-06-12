
import SwiftDatabase

public protocol SQLRecord: Migratable {
    associatedtype IDValue: Codable & Hashable & Sendable
    associatedtype Attribute: SQLAttribute

    var id: IDValue { get }
}