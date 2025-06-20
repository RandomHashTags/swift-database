
public struct ModelRevision: Sendable {
    public let version:(major: Int, minor: Int, patch: Int)

    /// Dictionary<FieldName, DataType>
    public let addedFields:[Field]

    /// Dictionary<FieldName, DataType>
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

// MARK: Field
extension ModelRevision {
    public struct Field: Sendable {
        public let name:String
        public let constraints:[Constraint]
        public package(set) var postgresDataType:PostgresDataType?
        public let defaultValue:String?

        public init(
            name: String,
            constraints: [Constraint] = [.notNull],
            postgresDataType: PostgresDataType? = nil,
            defaultValue: String? = nil
        ) {
            self.name = name
            self.constraints = constraints
            self.postgresDataType = postgresDataType
            self.defaultValue = defaultValue
        }
    }
}

// MARK: Field constraint
extension ModelRevision.Field {
    public enum Constraint: Sendable {
        case notNull
        case check(leftFieldName: String, rightFieldName: String)
        case unique
        case nullsNotDistinct
        case primaryKey
        
        /// - Parameters:
        ///   - table: the referenced table
        ///   - fieldName: the referenced field in the table; leave `nil` to default to the table's primary key
        case references(table: String, fieldName: String?)

        @inlinable
        public var name: String {
            switch self {
            case .notNull: "NOT NULL"
            case .check(let l, let r): "CHECK (\(l) > \(r))"
            case .unique: "UNIQUE"
            case .nullsNotDistinct: "NULLS NOT DISTINCT"
            case .primaryKey: "PRIMARY KEY"
            case .references(let table, let fieldName): "REFERENCES " + table + (fieldName != nil ? " (\(fieldName!))" : "")
            }
        }
    }
}