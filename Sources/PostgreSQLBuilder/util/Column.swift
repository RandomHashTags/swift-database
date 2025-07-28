
import ModelUtilities

extension PostgresSQLBuilder {
    public struct Column: PostgresSQLBuilderComponent { // TODO: finish
        public let name:String
        public let dataType:PostgresDataType
        public let collate:String?
        public let storage:Storage?
        public let compression:Compression?
        // inherits
        // partitionBy
        // partitionOf
        public let like:Like?
        public let null:Bool?
        // check
        // default
        // generatedAlwaysAs
        // generatedAsIdentity
        // unique
        // primaryKey
        // exclude
        // references
        public let deferrable:Bool?
        public let initiallyImmediate:Bool?
        // using
        public let with:[WithStorageParameter]
        public let withoutOIDs:Bool?
        public let onCommit:CommitBehavior?

        public init(
            name: String,
            dataType: PostgresDataType,
            collate: String? = nil,
            storage: Storage? = nil,
            compression: Compression? = nil,
            like: Like? = nil,
            null: Bool? = nil,
            deferrable: Bool? = nil,
            initiallyImmediate: Bool? = nil,
            with: [WithStorageParameter] = [],
            withoutOIDs: Bool? = nil,
            onCommit: CommitBehavior? = nil
        ) {
            self.name = name
            self.dataType = dataType
            self.collate = collate
            self.storage = storage
            self.compression = compression
            self.like = like
            self.null = null
            self.deferrable = deferrable
            self.initiallyImmediate = initiallyImmediate
            self.with = with
            self.withoutOIDs = withoutOIDs
            self.onCommit = onCommit
        }
    }
}

// MARK: SQL
extension PostgresSQLBuilder.Column {
    public var sql: String {
        var s = name
        s.append(" \(dataType.name)")
        if let collate {
            s.append(" COLLATE \(collate)")
        }
        if let storage {
            s.append(" \(storage.sql)")
        }
        if let compression {
            s.append(" \(compression.sql)")
        }
        if let like {
            s.append(" \(like.sql)")
        }
        if let null {
            s.append(" \(null ? "" : "NOT") NULL")
        }
        if let deferrable {
            s.append(" \(deferrable ? "" : "NOT ")DEFERRABLE")
        }
        if let initiallyImmediate {
            s.append(" INITIALLY \(initiallyImmediate ? "IMMEDIATE" : "DEFERRED")")
        }
        if !with.isEmpty {
            s.append(" WITH \(with.map({ $0.sql }).joined(separator: ", "))")
        }
        if let withoutOIDs, withoutOIDs {
            s.append(" WITHOUT OIDS")
        }
        if let onCommit {
            s.append(" ON COMMIT \(onCommit.sql)")
        }
        return s
    }
}

// MARK: Storage
extension PostgresSQLBuilder.Column {
    public enum Storage: String, PostgresSQLBuilderComponent {
        case plain
        case external
        case extended
        case main
        case `default`

        public var rawValueSQL: String {
            switch self {
            case .plain:    "PLAIN"
            case .external: "EXTERNAL"
            case .extended: "EXTENDED"
            case .main:     "MAIN"
            case .default:  "DEFAULT"
            }
        }

        public var sql: String {
            "STORAGE \(rawValueSQL)"
        }
    }
}

// MARK: Compression
extension PostgresSQLBuilder.Column {
    public enum Compression: String, PostgresSQLBuilderComponent {
        case pglz
        case lz4
        case `default` = "default"

        public var sql: String {
            rawValue
        }
    }
}

// MARK: Like
extension PostgresSQLBuilder.Column {
    public struct Like: PostgresSQLBuilderComponent {
        public let sourceTable:String
        public let options:[LikeOption]

        public var sql: String {
            var s = sourceTable
            if !options.isEmpty {
                s.append(options.map({ $0.sql }).joined(separator: " "))
            }
            return s
        }
    }
}

// MARK: Like option
extension PostgresSQLBuilder.Column {
    public enum LikeOption: String, PostgresSQLBuilderComponent {
        case comments
        case compression
        case constraints
        case defaults
        case generated
        case identity
        case indexes
        case statistics
        case storage
        case all

        public var rawValueSQL: String {
            switch self {
            case .comments:    "COMMENTS"
            case .compression: "COMPRESSION"
            case .constraints: "CONSTRAINTS"
            case .defaults:    "DEFAULTS"
            case .generated:   "GENERATED"
            case .identity:    "IDENTITY"
            case .indexes:     "INDEXES"
            case .statistics:  "STATISTICS"
            case .storage:     "STORAGE"
            case .all:         "ALL"
            }
        }

        public var sql: String {
            "INCLUDING \(rawValueSQL)"
        }
    }
}

// MARK: Commit behavior
extension PostgresSQLBuilder.Column {
    public enum CommitBehavior: String, PostgresSQLBuilderComponent {
        case preserveRows
        case deleteRows
        case drop

        public var sql: String {
            switch self {
            case .preserveRows: "PRESERVE ROWS"
            case .deleteRows:   "DELETE ROWS"
            case .drop:         "DROP"
            }
        }
    }
}