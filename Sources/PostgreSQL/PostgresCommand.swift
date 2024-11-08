//
//  PostgresDatabase.swift
//
//
//  Created by Evan Anderson on 11/7/24.
//

import SQL

public struct PostgresCommand : SQLCommand {
    public let sqlValue:String

    init(_ sqlValue: String) {
        self.sqlValue = sqlValue
    }
    public init(stringLiteral value: String) {
        sqlValue = value
    }
}
public extension PostgresCommand {
    static func unsafeRaw(_ sql: String) -> PostgresCommand { .init(sql) }
    static func unsafeExpression(command: PostgresCommand, _ arguments: PostgresCommand...) -> PostgresCommand {
        unsafeRaw(command.sqlValue + arguments.map({ $0.sqlValue }).joined(separator: " "))
    }
}
// MARK: Create Type
public extension PostgresCommand {
    static func createType(
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
    static let abort:PostgresCommand                   = unsafeRaw("ABORT")
    static func alter(_ alterable: Alterable) -> PostgresCommand { unsafeRaw("ALTER " + alterable.rawValue) }
    static let analyze:PostgresCommand                 = unsafeRaw("ANALYZE")
    static let begin:PostgresCommand                   = unsafeRaw("BEGIN")
    static let call:PostgresCommand                    = unsafeRaw("CALL")
    static let checkpoint:PostgresCommand              = unsafeRaw("CHECKPOINT")
    static let close:PostgresCommand                   = unsafeRaw("CLOSE")
    static let cluster:PostgresCommand                 = unsafeRaw("CLUSTER")
    static let comment:PostgresCommand                 = unsafeRaw("COMMENT")
    static let commit:PostgresCommand                  = unsafeRaw("COMMIT")
    static let commitPrepared:PostgresCommand          = unsafeRaw("COMMIT PREPARED")
    static let copy:PostgresCommand                    = unsafeRaw("COPY")
    static func create(_ creatable: Creatable) -> PostgresCommand { unsafeRaw("CREATE " + creatable.rawValue) }
    static let deallocate:PostgresCommand              = unsafeRaw("DEALLOCATE")
    static let declare:PostgresCommand                 = unsafeRaw("DECLARE")
    static let delete:PostgresCommand                  = unsafeRaw("DELETE")
    static let discard:PostgresCommand                 = unsafeRaw("DISCARD")
    static let `do`:PostgresCommand                    = unsafeRaw("DO")
    // drop
    static let end:PostgresCommand                     = unsafeRaw("END")
    static let execute:PostgresCommand                 = unsafeRaw("EXECUTE")
    static let explain:PostgresCommand                 = unsafeRaw("EXPLAIN")
    static let fetch:PostgresCommand                   = unsafeRaw("FETCH")
    static let grant:PostgresCommand                   = unsafeRaw("GRANT")
    static let importForeignSchema:PostgresCommand     = unsafeRaw("IMPORT FOREIGN SCHEMA")
    static let insert:PostgresCommand                  = unsafeRaw("INSERT")
    static let load:PostgresCommand                    = unsafeRaw("LOAD")
    static let lock:PostgresCommand                    = unsafeRaw("LOCK")
    static let merge:PostgresCommand                   = unsafeRaw("MERGE")
    static let move:PostgresCommand                    = unsafeRaw("MOVE")
    static let notify:PostgresCommand                  = unsafeRaw("NOTIFY")
    static let prepare:PostgresCommand                 = unsafeRaw("PREPARE")
    static let prepareTransaction:PostgresCommand      = unsafeRaw("PREPARE TRANSACTION")
    static let reassignOwned:PostgresCommand           = unsafeRaw("REASSIGN OWNED")
    static let refreshMaterializedView:PostgresCommand = unsafeRaw("REFRESH MATERIALIZED VIEW")
    static let reindex:PostgresCommand                 = unsafeRaw("REINDEX")
    static let releaseSavepoint:PostgresCommand        = unsafeRaw("RELEASE SAVEPOINT")
    static let reset:PostgresCommand                   = unsafeRaw("RESET")
    static let revoke:PostgresCommand                  = unsafeRaw("REVOKE")
    static let rollback:PostgresCommand                = unsafeRaw("ROLLBACK")
    static let rollbackPrepared:PostgresCommand        = unsafeRaw("ROLLBACK PREPARED")
    static let rollbackToSavepoint:PostgresCommand     = unsafeRaw("ROLLBACK TO SAVEPOINT")
    static let savepoint:PostgresCommand               = unsafeRaw("SAVEPOINT")
    static let securityLabel:PostgresCommand           = unsafeRaw("SECURITY LABEL")
    static let select:PostgresCommand                  = unsafeRaw("SELECT")
    static let selectInto:PostgresCommand              = unsafeRaw("SELECT INTO")
    static let set:PostgresCommand                     = unsafeRaw("SET")
    static let setConstraints:PostgresCommand          = unsafeRaw("SET CONSTRAINTS")
    static let setRole:PostgresCommand                 = unsafeRaw("SET ROLE")
    static let setSessionAuthorization:PostgresCommand = unsafeRaw("SET SESSION AUTHORIZATION")
    static let setTransaction:PostgresCommand          = unsafeRaw("SET TRANSACTION")
    static let show:PostgresCommand                    = unsafeRaw("show")
    static let startTransaction:PostgresCommand        = unsafeRaw("START TRANSACTION")
    static let truncate:PostgresCommand                = unsafeRaw("TRUNCATE")
    static let unlisten:PostgresCommand                = unsafeRaw("UNLISTEN")
    static let update:PostgresCommand                  = unsafeRaw("UPDATE")
    static let vacuum:PostgresCommand                  = unsafeRaw("VACUUM")
    static let values:PostgresCommand                  = unsafeRaw("VALUES")
}

// MARK: Alterable
public extension PostgresCommand {
    enum Alterable : String {
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
public extension PostgresCommand {
    enum Creatable : String {
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