
public struct TablePartition: Sendable {
    public let form:Form
    public let column:String

    public init(
        form: Form,
        column: String
    ) {
        self.form = form
        self.column = column
    }

    public func shortSQL(databaseType: DatabaseType) -> String? {
        switch databaseType {
        case .postgreSQL:
            "PARTITION BY " + form.name.uppercased() + "(" + column + ")"
        default:
            nil
        }
    }

    public func createSQL(
        databaseType: DatabaseType,
        schema: String,
        table: String,
        partitionName: String
    ) -> String? {
        guard var sql = form.sql(databaseType: databaseType) else { return nil }
        sql += ";"
        switch databaseType {
        case .postgreSQL:
            return "CREATE TABLE " + schema + "." + partitionName + " PARTITION OF " + schema + "." + table + " " + sql
        default:
            return nil
        }
    }
}

// MARK: Form
extension TablePartition {
    // TODO: support multilevel partitioning
    public enum Form: Sendable {
        case hash(modulus: Int, remainder: Int)
        case list(by: String)
        case range(from: String, to: String)

        public var name: String {
            switch self {
            case .hash:  "HASH"
            case .list:  "LIST"
            case .range: "RANGE"
            }
        }

        public func partitionSQL(
            databaseType: DatabaseType,
            column: String
        ) -> String? {
            switch databaseType {
            case .postgreSQL:
                return "PARTITION BY " + name + "(" + column + ")"
            default:
                return nil
            }
        }

        public func sql(databaseType: DatabaseType) -> String? {
            switch self {
            case .hash(let modulus, let remainder):
                hashSQL(databaseType, modulus: modulus, remainder: remainder)
            case .list(let by):
                listSQL(databaseType, by: by)
            case .range(let from, let to):
                rangeSQL(databaseType, from: from, to: to)
            }
        }

        private func hashSQL(_ databaseType: DatabaseType, modulus: Int, remainder: Int) -> String? {
            switch databaseType {
            case .postgreSQL:
                "FOR VALUES WITH (MODULUS \(modulus), REMAINDER \(remainder))"
            default:
                nil
            }
        }

        private func listSQL(_ databaseType: DatabaseType, by: String) -> String? {
            switch databaseType {
            case .postgreSQL:
                "FOR VALUES IN (" + by + ")"
            default:
                nil
            }
        }

        private func rangeSQL(_ databaseType: DatabaseType, from: String, to: String) -> String? {
            switch databaseType {
            case .postgreSQL:
                "FOR VALUES FROM (\(from)) TO (\(to))"
            default:
                nil
            }
        }
    }
}