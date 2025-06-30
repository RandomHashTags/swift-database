
public struct ModelRevision: Sendable {
    public let newTableName:String?
    public let addedFields:[Column]
    public let updatedFields:[Column]
    public let renamedFields:[(from: String, to: String)]
    public let removedFields:Set<String>
    
    public init(
        newTableName: String? = nil,
        addedFields: [Column] = [],
        updatedFields: [Column] = [],
        renamedFields: [(from: String, to: String)] = [],
        removedFields: Set<String> = []
    ) {
        self.newTableName = newTableName
        self.addedFields = addedFields
        self.updatedFields = updatedFields
        self.renamedFields = renamedFields
        self.removedFields = removedFields
    }
    public init<T: RawModelIdentifier>(
        newTableName: T? = nil,
        addedFields: [Column] = [],
        updatedFields: [Column] = [],
        renamedFields: [(from: String, to: String)] = [],
        removedFields: Set<String> = []
    ) {
        self.newTableName = newTableName?.rawValue
        self.addedFields = addedFields
        self.updatedFields = updatedFields
        self.renamedFields = renamedFields
        self.removedFields = removedFields
    }
}