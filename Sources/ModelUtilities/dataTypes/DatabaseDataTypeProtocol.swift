
public protocol DatabaseDataTypeProtocol: Sendable, Equatable {
    init?(rawValue: String)

    var name: String { get }

    var swiftDataType: String { get }
}