
extension ModelRevision.Column {
    public enum Constraint: Hashable, Sendable {
        case notNull
        case check(leftFieldName: String, rightFieldName: String)
        case unique
        case nullsNotDistinct
        case primaryKey
        
        /// - Parameters:
        ///   - schema: the schema where the table is located
        ///   - table: the referenced table
        ///   - fieldName: the referenced field in the table
        case references(schema: String, table: String, fieldName: String)

        @inlinable
        public var name: String {
            switch self {
            case .notNull: "NOT NULL"
            case .check(let l, let r): "CHECK (\(l) > \(r))"
            case .unique: "UNIQUE"
            case .nullsNotDistinct: "NULLS NOT DISTINCT"
            case .primaryKey: "PRIMARY KEY"
            case .references(let schema, let table, let fieldName): "REFERENCES " + schema + "." + table + " (" + fieldName + ")"
            }
        }
    }
}