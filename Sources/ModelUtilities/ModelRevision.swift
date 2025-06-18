
public struct ModelRevision: Sendable {
    public let version:(major: Int, minor: Int, patch: Int)

    /// Dictionary<FieldName, DataType>
    public let addedFields:[String:String]

    /// Dictionary<FieldName, DataType>
    public let updatedFields:[String:String]

    public let removedFields:Set<String>
    
    public init(
        version: (major: Int, minor: Int, patch: Int),
        addedFields: [String:String] = [:],
        updatedFields: [String:String] = [:],
        removedFields: Set<String> = []
    ) {
        self.version = version
        self.addedFields = addedFields
        self.updatedFields = updatedFields
        self.removedFields = removedFields
    }
}