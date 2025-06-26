
public struct ModelRevision: Sendable {
    public let newTableName:String?
    public let addedFields:[Field]
    public let updatedFields:[Field]
    public let renamedFields:[(from: String, to: String)]
    public let removedFields:Set<String>
    
    public init(
        newTableName: String? = nil,
        addedFields: [Field] = [],
        updatedFields: [Field] = [],
        renamedFields: [(from: String, to: String)] = [],
        removedFields: Set<String> = []
    ) {
        self.newTableName = newTableName
        self.addedFields = addedFields
        self.updatedFields = updatedFields
        self.renamedFields = renamedFields
        self.removedFields = removedFields
    }
}