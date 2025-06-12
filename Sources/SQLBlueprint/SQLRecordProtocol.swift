
import SwiftDatabase

public protocol SQLRecordProtocol: MigratableProtocol {
    associatedtype IDValue: Codable & Hashable & Sendable
    associatedtype Attribute: SQLAttributeProtocol

    var id: IDValue { get }
}