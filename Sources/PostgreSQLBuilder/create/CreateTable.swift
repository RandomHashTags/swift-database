
extension PostgresSQLBuilder {
    public struct CreateTable: PostgresSQLBuilderComponent {

        public let visibility:Visibility?
        public let tableName:String
        public let ifNotExists:Bool
        public let columns:[Column]
        public let tablespace:String?
        public let usingIndexTablespace:String?

        public init(
            visibility: Visibility? = nil,
            tableName: String,
            ifNotExists: Bool = false,
            columns: [Column] = [],
            tablespace: String? = nil,
            usingIndexTablespace: String? = nil
        ) {
            self.visibility = visibility
            self.tableName = tableName
            self.ifNotExists = ifNotExists
            self.columns = columns
            self.tablespace = tablespace
            self.usingIndexTablespace = usingIndexTablespace
        }
    }
}

extension PostgresSQLBuilder.CreateTable {
    public enum Visibility: PostgresSQLBuilderComponent {
        case globalTemporary
        case globalTemp
        case localTemporary
        case local
        case unlogged

        public var sql: String {
            switch self {
            case .globalTemporary: "GLOBAL TEMPORARY"
            case .globalTemp:      "GLOBAL TEMP"
            case .localTemporary:  "LOCAL TEMPORARY"
            case .local:           "LOCAL"
            case .unlogged:        "UNLOGGED"
            }
        }
    }
}

extension PostgresSQLBuilder.CreateTable {
    public var sql: String {
        var s = "CREATE "
        if let visibility {
            s.append("\(visibility.sql) ")
        }
        s.append(tableName)
        if ifNotExists {
            s.append(" IF NOT EXISTS")
        }
        if !columns.isEmpty {
            s.append(columns.map({ $0.sql }).joined(separator: ","))
        }
        if let tablespace {
            s.append(" TABLESPACE \(tablespace)")
        }
        if let usingIndexTablespace {
            s.append(" USING INDEX TABLESPACE \(usingIndexTablespace)")
        }
        return s
    }
}