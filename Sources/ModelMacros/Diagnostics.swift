
import ModelUtilities
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
    static func somethingWentWrong(expr: some ExprSyntaxProtocol, message: String = "") -> Diagnostic {
        Diagnostic(node: expr, message: DiagnosticMsg(id: "somethingWentWrong", message: "Something went wrong\(message.isEmpty ? "" : "; \(message)")"))
    }
    static func stringLiteralContainsIllegalCharacter(expr: some ExprSyntaxProtocol, char: Character) -> Diagnostic {
        Diagnostic(node: expr, message: DiagnosticMsg(id: "stringLiteralContainsIllegalCharacter", message: "String literal contains illegal character: '\(char)'"))
    }
}

// MARK: Expectations
extension DiagnosticMsg {
    static func expectedArrayExpr(expr: some ExprSyntaxProtocol) -> Diagnostic {
        Diagnostic(node: expr, message: DiagnosticMsg(id: "expectedArrayExpr", message: "Expected array expression"))
    }
    static func expectedFunctionCallExpr(expr: some ExprSyntaxProtocol) -> Diagnostic {
        Diagnostic(node: expr, message: DiagnosticMsg(id: "expectedFunctionCallExpr", message: "Expected function call expression"))
    }
    static func expectedMemberAccessExpr(expr: some ExprSyntaxProtocol) -> Diagnostic {
        Diagnostic(node: expr, message: DiagnosticMsg(id: "expectedMemberAccessExpr", message: "Expected member access expression"))
    }
    static func expectedFunctionCallOrMemberAccessExpr(expr: some ExprSyntaxProtocol) -> Diagnostic {
        Diagnostic(node: expr, message: DiagnosticMsg(id: "expectedFunctionCallOrMemberAccessExpr", message: "Expected function call or member access expression; got \(expr.kind)"))
    }
    static func expectedStringLiteral(expr: some ExprSyntaxProtocol) -> Diagnostic {
        Diagnostic(node: expr, message: DiagnosticMsg(id: "expectedStringLiteral", message: "Expected string literal; got \(expr.kind)"))
    }
    static func expectedStringLiteralOrMemberAccess(expr: some ExprSyntaxProtocol) -> Diagnostic {
        Diagnostic(node: expr, message: DiagnosticMsg(id: "expectedStringLiteralOrMemberAccess", message: "Expected string literal or member access; got \(expr.kind)"))
    }
    static func expectedRawModelIdentifier(expr: some ExprSyntaxProtocol) -> Diagnostic {
        Diagnostic(node: expr, message: DiagnosticMsg(id: "expectedRawModelIdentifier", message: "Expected a raw model identifier (string literal, member access or key path); got \(expr.kind)"))
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
    static func revisionMissingTableName(expr: ExprSyntax) -> Diagnostic {
        Diagnostic(node: expr, message: DiagnosticMsg(id: "revisionMissingTableName", message: "Revision doesn't have a table name"))
    }
}

extension DiagnosticMsg {
    static func notNullFieldMissingDefaultValue(column: ModelRevision.Column.Compiled) -> Diagnostic {
        Diagnostic(node: column.expr, message: DiagnosticMsg(id: "notNullFieldMissingDefaultValue", message: "Field '\(column.columnName)' with constraint '.notNull' is missing a default value"))
    }
    static func fieldAlreadyExists(column: ModelRevision.Column.Compiled) -> Diagnostic {
        Diagnostic(node: column.expr, message: DiagnosticMsg(id: "fieldAlreadyExists", message: "Field '\(column.columnName)' already exists at this point"))
    }
}

extension DiagnosticMsg {
    static func missingPrimaryKey() -> DiagnosticMsg {
        DiagnosticMsg(id: "missingPrimaryKey", message: "ModelRevision doesn't contain a primary key field at this point")
    }
    static func cannotUpdateFieldThatDoesntExist(column: ModelRevision.Column.Compiled) -> Diagnostic {
        Diagnostic(node: column.expr, message: DiagnosticMsg(id: "cannotUpdateFieldThatDoesntExist", message: "Field '\(column.columnName)' cannot be updated because it doesn't exist at this point; ignoring", severity: .warning))
    }
    static func cannotUpdateFieldWithIdenticalDataType(column: ModelRevision.Column.Compiled) -> Diagnostic {
        Diagnostic(node: column.expr, message: DiagnosticMsg(id: "cannotUpdateFieldWithIdenticalDataType", message: "Field '\(column.columnName)' cannot be updated because the data types are identical at this point; ignoring", severity: .warning))
    }
    static func cannotRemoveFieldThatDoesntExist(expr: ExprSyntax, columnName: String) -> Diagnostic {
        Diagnostic(node: expr, message: DiagnosticMsg(id: "cannotRemoveFieldThatDoesntExist", message: "Field '\(columnName)' cannot be removed because it doesn't exist at this point; ignoring", severity: .warning))
    }
    static func cannotRenameFieldThatDoesntExist(expr: ExprSyntax, columnName: String) -> Diagnostic {
        Diagnostic(node: expr, message: DiagnosticMsg(id: "cannotRenameFieldThatDoesntExist", message: "Field '\(columnName)' cannot be renamed because it doesn't exist at this point; ignoring", severity: .warning))
    }
    static func cannotRenameFieldToExistingField(field: (expr: ExprSyntax, from: String, to: String)) -> Diagnostic {
        Diagnostic(node: field.expr, message: DiagnosticMsg(id: "cannotRenameFieldToExistingField", message: "Field '\(field.from)' cannot be renamed to '\(field.to)' because a field named '\(field.to)' already exists at this point"))
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