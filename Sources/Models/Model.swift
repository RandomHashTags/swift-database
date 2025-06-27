
import ModelUtilities

@attached(extension, names: arbitrary)
public macro Model(
    supportedDatabases: [DatabaseType],
    schema: String = "public",
    schemaAlias: String? = nil,
    table: String,
    selectFilters: [(returnedFields: [String], condition: ModelCondition)] = [],
    revisions: [ModelRevision]
) = #externalMacro(module: "ModelMacros", type: "ModelMacro")

public protocol Model: AnyModel, ~Copyable {
    associatedtype IDValue: Sendable
    var id: IDValue { get }

    func requireID() throws -> IDValue
}

extension Model where IDValue: FixedWidthInteger {
    @inlinable
    public func requireID() throws -> IDValue {
        guard id > 0 else {
            throw ModelError.idRequired("\(Self.self) `id` is required to be > 0")
        }
        return id
    }
}

extension Model where IDValue: OptionalProtocol {
    @inlinable
    public func requireID() throws -> IDValue {
        guard let id = id.value() else {
            throw ModelError.idRequired("\(Self.self) `id` is required to be non-nil")
        }
        return .init(id)
    }
}