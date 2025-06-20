
public struct ModelRevision: Sendable {
    public let version:(major: Int, minor: Int, patch: Int)
    public let addedFields:[Field]
    public let updatedFields:[Field]
    public let removedFields:Set<String>
    
    public init(
        version: (major: Int, minor: Int, patch: Int),
        addedFields: [Field] = [],
        updatedFields: [Field] = [],
        removedFields: Set<String> = []
    ) {
        self.version = version
        self.addedFields = addedFields
        self.updatedFields = updatedFields
        self.removedFields = removedFields
    }
}