
extension ModelRevision.Field {
    public enum Constraint: Sendable, Equatable {
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