
public protocol DatabaseDataTypeProtocol: Sendable {
    init?(rawValue: String)

    var name: String { get }

    var swiftDataType: String { get }
}