
public struct ModelRevision: Sendable {
    public let addedFields:[Field]
    public let updatedFields:[Field]
    public let renamedFields:[(from: String, to: String)]
    public let removedFields:Set<String>
    
    public init(
        addedFields: [Field] = [],
        updatedFields: [Field] = [],
        renamedFields: [(from: String, to: String)] = [],
        removedFields: Set<String> = []
    ) {
        self.addedFields = addedFields
        self.updatedFields = updatedFields
        self.renamedFields = renamedFields
        self.removedFields = removedFields
    }
}