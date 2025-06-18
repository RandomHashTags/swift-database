
import ModelUtilities

@attached(extension, names: arbitrary)
public macro Model(
    supportedDatabases: [DatabaseType],
    schema: String,
    schemaAlias: String? = nil,
    selectFilters: [(returnedFields: [String], condition: ModelCondition)] = [],
    revisions: [ModelRevision]
) = #externalMacro(module: "ModelMacros", type: "ModelMacro")

public protocol Model: AnyModel, ~Copyable {
    associatedtype IDValue: Codable, Sendable
    var id: IDValue? { get set }
}

extension Model {
    @inlinable
    public func requireID() throws -> IDValue {
        guard let id else {
            throw ModelError.idRequired("\(Self.self) `id` found to be nil")
        }
        return id
    }
}