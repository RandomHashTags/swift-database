
import ModelUtilities
import PostgreSQLBlueprint

public struct PostgresCommand: PostgresCommandProtocol {
    public let sqlValue:String

    @usableFromInline
    init(_ sqlValue: String) {
        self.sqlValue = sqlValue
    }
    public init(stringLiteral value: String) {
        sqlValue = value
    }
}

extension PostgresCommand {
    @inlinable
    public static func unsafeRaw(_ sql: String) -> PostgresCommand {
        .init(sql)
    }

    @inlinable
    public static func unsafeExpression(
        command: PostgresCommand,
        _ arguments: PostgresCommand...
    ) -> PostgresCommand {
        unsafeRaw(command.sqlValue + arguments.map({ $0.sqlValue }).joined(separator: " "))
    }
}
// MARK: Create Type
extension PostgresCommand {
    public static func createType(
        name: String,
        attributeName: String,
        dataType: String,
        collation: String,
        label: String,
        subtype: String,
        subtypeOperatorClass: String,
        canonicalFunction: String,
        subtypeDiffFunction: String,
        multirangeTypeName: String,
        inputFunction: String,
        outputFunction: String,
        receiveFunction: String? = nil,
        sendFunction: String? = nil,
        typeModifierInputFunction: String? = nil,
        typeModifierOutputFunction: String? = nil,
        analyzeFunction: String? = nil,
        subscriptFunction: String? = nil,
        internalLength: Int,
        alignment: Int? = nil,
        storage: String? = nil,
        likeType: String,
        category: String,
        preferred: String,
        default: PostgresDataType? = nil,
        element: PostgresDataType? = nil,
        delimiter: String = ",",
        collatable: Bool = false
    ) {
        unsafeExpression(command: .create(.type))
    }
}
// MARK: Literal commands
public extension PostgresCommand {
    static let abort                   = unsafeRaw("ABORT")
    static func alter(_ alterable: Alterable) -> PostgresCommand { unsafeRaw("ALTER " + alterable.rawValue) }
    static let analyze                 = unsafeRaw("ANALYZE")
    static let begin                   = unsafeRaw("BEGIN")
    static let call                    = unsafeRaw("CALL")
    static let checkpoint              = unsafeRaw("CHECKPOINT")
    static let close                   = unsafeRaw("CLOSE")
    static let cluster                 = unsafeRaw("CLUSTER")
    static let comment                 = unsafeRaw("COMMENT")
    static let commit                  = unsafeRaw("COMMIT")
    static let commitPrepared          = unsafeRaw("COMMIT PREPARED")
    static let copy                    = unsafeRaw("COPY")
    static func create(_ creatable: Creatable) -> PostgresCommand { unsafeRaw("CREATE " + creatable.rawValue) }
    static let deallocate              = unsafeRaw("DEALLOCATE")
    static let declare                 = unsafeRaw("DECLARE")
    static let delete                  = unsafeRaw("DELETE")
    static let discard                 = unsafeRaw("DISCARD")
    static let `do`                    = unsafeRaw("DO")
    // drop
    static let end                     = unsafeRaw("END")
    static let execute                 = unsafeRaw("EXECUTE")
    static let explain                 = unsafeRaw("EXPLAIN")
    static let fetch                   = unsafeRaw("FETCH")
    static let grant                   = unsafeRaw("GRANT")
    static let importForeignSchema     = unsafeRaw("IMPORT FOREIGN SCHEMA")
    static let insert                  = unsafeRaw("INSERT")
    static let load                    = unsafeRaw("LOAD")
    static let lock                    = unsafeRaw("LOCK")
    static let merge                   = unsafeRaw("MERGE")
    static let move                    = unsafeRaw("MOVE")
    static let notify                  = unsafeRaw("NOTIFY")
    static let prepare                 = unsafeRaw("PREPARE")
    static let prepareTransaction      = unsafeRaw("PREPARE TRANSACTION")
    static let reassignOwned           = unsafeRaw("REASSIGN OWNED")
    static let refreshMaterializedView = unsafeRaw("REFRESH MATERIALIZED VIEW")
    static let reindex                 = unsafeRaw("REINDEX")
    static let releaseSavepoint        = unsafeRaw("RELEASE SAVEPOINT")
    static let reset                   = unsafeRaw("RESET")
    static let revoke                  = unsafeRaw("REVOKE")
    static let rollback                = unsafeRaw("ROLLBACK")
    static let rollbackPrepared        = unsafeRaw("ROLLBACK PREPARED")
    static let rollbackToSavepoint     = unsafeRaw("ROLLBACK TO SAVEPOINT")
    static let savepoint               = unsafeRaw("SAVEPOINT")
    static let securityLabel           = unsafeRaw("SECURITY LABEL")
    static let select                  = unsafeRaw("SELECT")
    static let selectInto              = unsafeRaw("SELECT INTO")
    static let set                     = unsafeRaw("SET")
    static let setConstraints          = unsafeRaw("SET CONSTRAINTS")
    static let setRole                 = unsafeRaw("SET ROLE")
    static let setSessionAuthorization = unsafeRaw("SET SESSION AUTHORIZATION")
    static let setTransaction          = unsafeRaw("SET TRANSACTION")
    static let show                    = unsafeRaw("show")
    static let startTransaction        = unsafeRaw("START TRANSACTION")
    static let truncate                = unsafeRaw("TRUNCATE")
    static let unlisten                = unsafeRaw("UNLISTEN")
    static let update                  = unsafeRaw("UPDATE")
    static let vacuum                  = unsafeRaw("VACUUM")
    static let values                  = unsafeRaw("VALUES")
}

// MARK: Alterable
extension PostgresCommand {
    public enum Alterable: String {
        case aggregate               = "AGGREGATE"
        case collation               = "COLLATION"
        case database                = "DATABASE"
        case defaultPrivileges       = "DEFAULT PRIVILEGES"
        case domain                  = "DOMAIN"
        case eventTrigger            = "EVENT TRIGGER"
        case `extension`             = "EXTENSION"
        case foreignDataWrapper      = "FOREIGN DATA WRAPPER"
        case foreignTable            = "FOREIGN TABLE"
        case function                = "FUNCTION"
        case group                   = "GROUP"
        case index                   = "INDEX"
        case language                = "LANGUAGE"
        case largeObject             = "LARGE OBJECT"
        case materializedView        = "MATERIALIZED VIEW"
        case `operator`              = "OPERATOR"
        case operatorClass           = "OPERATOR CLASS"
        case operatorFamily          = "OPERATOR FAMILY"
        case policy                  = "POLICY"
        case procedure               = "PROCEDURE"
        case publication             = "PUBLICATION"
        case role                    = "ROLE"
        case routine                 = "ROUTINE"
        case rule                    = "RULE"
        case schema                  = "SCHEMA"
        case sequence                = "SEQUENCE"
        case server                  = "SERVER"
        case statistics              = "STATISTICS"
        case subscription            = "SUBSCRIPTION"
        case system                  = "SYSTEM"
        case table                   = "TABLE"
        case tablespace              = "TABLESPACE"
        case textSearchConfiguration = "TEXT SEARCH CONFIGURATION"
        case textSearchDictionary    = "TEXT SEARCH DICTIONARY"
        case textSearchParser        = "TEXT SEARCH PARSER"
        case textSearchTemplate      = "TEXT SEARCH TEMPLATE"
        case trigger                 = "TRIGGER"
        case type                    = "TYPE"
        case user                    = "USER"
        case userMapping             = "USER MAPPING"
        case view                    = "VIEW"
    }
}
// MARK: Creatable
extension PostgresCommand {
    public enum Creatable: String {
        case accessMethod            = "ACCESS METHOD"
        case aggregate               = "AGGREGATE"
        case cast                    = "CAST"
        case collation               = "COLLATION"
        case conversion              = "CONVERSION"
        case database                = "DATABASE"
        case domain                  = "DOMAIN"
        case eventTrigger            = "EVENT TRIGGER"
        case `extension`             = "EXTENSION"
        case foreignDataWrapper      = "FOREIGN DATA WRAPPER"
        case foreignTable            = "FOREIGN TABLE"
        case function                = "FUNCTION"
        case group                   = "GROUP"
        case index                   = "INDEX"
        case language                = "LANGUAGE"
        case materializedView        = "MATERIALIZED VIEW"
        case `operator`              = "OPERATOR"
        case operatorClass           = "OPERATOR CLASS"
        case operatorFamily          = "OPERATOR FAMILY"
        case policy                  = "POLICY"
        case procedure               = "PROCEDURE"
        case publication             = "PUBLICATION"
        case role                    = "ROLE"
        case rule                    = "RULE"
        case schema                  = "SCHEMA"
        case sequence                = "SEQUENCE"
        case server                  = "SERVER"
        case statistics              = "STATISTICS"
        case subscription            = "SUBSCRIPTION"
        case table                   = "TABLE"
        case tableAs                 = "TABLE AS"
        case tablespace              = "TABLESPACE"
        case textSearchConfiguration = "TEXT SEARCH CONFIGURATION"
        case textSearchDictionary    = "TEXT SEARCH DICTIONARY"
        case textSearchParser        = "TEXT SEARCH PARSER"
        case textSearchTemplate      = "TEXT SEARCH TEMPLATE"
        case transform               = "TRANSFORM"
        case trigger                 = "TRIGGER"
        case type                    = "TYPE"
        case user                    = "USER"
        case userMapping             = "USER MAPPING"
        case view                    = "VIEW"
    }
}