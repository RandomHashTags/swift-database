
import SwiftDiagnostics
import SwiftSyntax

// MARK: DiagnosticMsg
struct DiagnosticMsg: DiagnosticMessage {
    let message:String
    let diagnosticID:MessageID
    let severity:DiagnosticSeverity

    init(id: String, message: String, severity: DiagnosticSeverity = .error) {
        self.message = message
        self.diagnosticID = MessageID(domain: "ModelMacros", id: id)
        self.severity = severity
    }
}
extension DiagnosticMsg: FixItMessage {
    var fixItID: MessageID { diagnosticID }
}

// MARK: General
extension DiagnosticMsg {
    static func expectedStringLiteral(expr: ExprSyntax) -> Diagnostic {
        Diagnostic(node: expr, message: DiagnosticMsg(id: "expectedStringLiteral", message: "Expected string literal"))
    }
}

// MARK: Models

extension DiagnosticMsg {
    static func failedToParseModelCondition() -> DiagnosticMsg {
        DiagnosticMsg(id: "failedToParseModelCondition", message: "Failed to parse ModelCondition")
    }
    static func failedToParseModelConditionValue() -> DiagnosticMsg {
        DiagnosticMsg(id: "failedToParseModelConditionValue", message: "Failed to parse ModelCondition.Value")
    }
    static func failedToParseModelRevisionField() -> DiagnosticMsg {
        DiagnosticMsg(id: "failedToParseModelRevisionField", message: "Failed to parse ModelRevision.Field")
    }
    static func failedToParseModelRevisionFieldConstraint() -> DiagnosticMsg {
        DiagnosticMsg(id: "failedToParseModelRevisionFieldConstraint", message: "Failed to parse ModelRevision.Field.Constraint")
    }
    static func failedToParseModelRevision() -> DiagnosticMsg {
        DiagnosticMsg(id: "failedToParseModelRevision", message: "Failed to parse ModelRevision")
    }
}

extension DiagnosticMsg {
    static func notNullFieldMissingDefaultValue() -> DiagnosticMsg {
        DiagnosticMsg(id: "notNullFieldMissingDefaultValue", message: "Field with constraint '.notNull' is missing a default value")
    }
    static func fieldAlreadyExists() -> DiagnosticMsg {
        DiagnosticMsg(id: "fieldAlreadyExists", message: "Field already exists at this point")
    }
}

extension DiagnosticMsg {
    static func missingPrimaryKey() -> DiagnosticMsg {
        DiagnosticMsg(id: "missingPrimaryKey", message: "ModelRevision doesn't contain a primary key field at this point")
    }
    static func cannotUpdateFieldThatDoesntExist() -> DiagnosticMsg {
        DiagnosticMsg(id: "cannotUpdateFieldThatDoesntExist", message: "Field cannot be updated because it doesn't exist at this point", severity: .warning)
    }
    static func cannotRemoveFieldThatDoesntExist() -> DiagnosticMsg {
        DiagnosticMsg(id: "cannotRemoveFieldThatDoesntExist", message: "Field cannot be removed because it doesn't exist at this point", severity: .warning)
    }
}

// MARK: Postgres
extension DiagnosticMsg {
    static func modelRevisionMissingPostgresDataType() -> DiagnosticMsg {
        DiagnosticMsg(id: "modelRevisionMissingPostgresDataType", message: "ModelRevision's `postgresDataType` variable cannot be nil")
    }
    static func modelRevisionFieldMissingPostgresDataType() -> DiagnosticMsg {
        DiagnosticMsg(id: "modelRevisionFieldMissingPostgresDataType", message: "ModelRevision.Field's `postgresDataType` variable cannot be nil")
    }
}