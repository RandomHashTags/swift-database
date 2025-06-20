
import ModelUtilities
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

enum ModelMacro {
}

extension ModelMacro: ExtensionMacro {
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let structure = declaration.as(StructDeclSyntax.self) else { return [] }
        guard let args = node.arguments?.children(viewMode: .all) else { return [] }

        let structureName = structure.name.text

        var supportedDatabases = Set<DatabaseType>()
        var schema = ""
        var alias:String? = nil
        var selectFilters = [(fields: [String], condition: ModelCondition)]()
        var revisions = [ModelRevision.Compiled]()
        var members = [String]()
        for arg in args {
            if let child = arg.as(LabeledExprSyntax.self) {
                switch child.label?.text {
                case "supportedDatabases":
                    if let array = child.expression.array?.elements {
                        for element in array {
                            if let s = element.expression.memberAccess?.declName.baseName.text, let type = DatabaseType(rawValue: s) {
                                supportedDatabases.insert(type)
                            }
                        }
                    }
                case "schema":
                    schema = child.expression.stringLiteral?.text ?? ""
                case "alias":
                    alias = child.expression.stringLiteral?.text
                case "revisions":
                    revisions = child.expression.array?.elements.compactMap({ ModelRevision.parse(context: context, expr: $0.expression) }) ?? []
                case "selectFilters":
                    if let array = child.expression.array?.elements {
                        for element in array {
                            if let tuple = element.expression.tuple {
                                var fields:[String]? = nil
                                var condition:ModelCondition? = nil
                                for (i, t) in tuple.elements.enumerated() {
                                    switch i {
                                    case 0:
                                        fields = t.expression.array?.elements.compactMap({ $0.expression.stringLiteral?.text })
                                    case 1:
                                        condition = ModelCondition.parse(context: context, expr: t.expression)
                                    default:
                                        break
                                    }
                                }
                                if let fields, let condition {
                                    selectFilters.append((fields, condition))
                                }
                            }
                        }
                    }
                default:
                    break
                }
            }
        }
        members.append("@inlinable public static var schema: String { \"\(schema)\" }")
        members.append("@inlinable public static var alias: String? { \(alias == nil ? "nil" : "\"\(alias!)\"") }")

        if let initialVersion = revisions.first?.version {
            var latestFields = [ModelRevision.Field.Compiled]()
            var latestFieldKeys = Set<String>()
            for revision in revisions {
                let isInitial = revision.version == initialVersion
                for field in revision.addedFields {
                    if !latestFieldKeys.contains(field.name) {
                        if !isInitial && field.constraints.contains(.notNull) && field.defaultValue == nil {
                            context.diagnose(Diagnostic(node: field.expr, message: DiagnosticMsg.notNullFieldMissingDefaultValue()))
                            continue
                        }
                        latestFields.append(field)
                    } else {
                        context.diagnose(Diagnostic(node: revision.expr, message: DiagnosticMsg.fieldAlreadyExists(name: field.name)))
                        continue
                    }
                    latestFieldKeys.insert(field.name)
                }
                for field in revision.updatedFields {
                    if let index = latestFields.firstIndex(where: { $0.name == field.name }) {
                        latestFields[index].postgresDataType = field.postgresDataType
                    } else {
                        context.diagnose(Diagnostic(node: field.expr, message: DiagnosticMsg.cannotUpdateFieldThatDoesntExist()))
                    }
                }
                for field in revision.removedFields {
                    if let index = latestFields.firstIndex(where: { $0.name == field.name }) {
                        latestFields.remove(at: index)
                    } else {
                        context.diagnose(Diagnostic(node: field.expr, message: DiagnosticMsg.cannotRemoveFieldThatDoesntExist()))
                        continue
                    }
                    latestFieldKeys.remove(field.name)
                }
                // make sure a primary key exists after applying this revision
                if latestFields.first(where: { $0.constraints.contains(.primaryKey) }) == nil {
                    context.diagnose(Diagnostic(node: revision.expr, message: DiagnosticMsg.missingPrimaryKey()))
                }
            }
            members.append(preparedStatements(context: context, structureName: structureName, supportedDatabases: supportedDatabases, schema: schema, selectFilters: selectFilters, fields: latestFields))
            members.append(migrations(context: context, supportedDatabases: supportedDatabases, schema: schema, revisions: revisions))
            members.append(compileSafety(structureName: structureName, fields: latestFields))
        }
        let content = members.map({ .init(stringLiteral: "    " + $0 + "\n") }).joined()
        return try [
            .init(.init(stringLiteral: "extension \(structureName) {\n\(content)\n}"))
        ]
    }
}

// MARK: Compile safety
extension ModelMacro {
    static func compileSafety(
        structureName: String,
        fields: [ModelRevision.Field.Compiled]
    ) -> String {
        var safetyString = "enum Safety {"
        for field in fields {
            safetyString += "\n        var \(field.name): AnyKeyPath { \\\(structureName).\(field.name) }"
        }
        safetyString += "\n    }"
        return safetyString
    }
}

// MARK: PreparedStatement
extension ModelMacro {
    struct PreparedStatement: Sendable {
        let name:String
        let parameters:[ModelRevision.Field.Compiled]
        let returningFields:[ModelRevision.Field.Compiled]
        let sql:String
    }
}

// MARK: Parse model condition
extension ModelCondition {
    static func parse(
        context: some MacroExpansionContext,
        expr: ExprSyntax
    ) -> Self? {
        guard let functionCall = expr.functionCall,
                functionCall.calledExpression.declReference?.baseName.text == "ModelCondition" else {
            context.diagnose(Diagnostic(node: expr, message: DiagnosticMsg.failedToParseModelCondition()))
            return nil
        }
        var name:String? = nil
        var firstCondition:ModelCondition.Value? = nil
        var additionalConditions = [(joiningOperator: JoiningOperator, condition: Value)]()
        for argument in functionCall.arguments {
            switch argument.label?.text {
            case "name":
                name = argument.expression.stringLiteral?.text
            case "firstCondition":
                firstCondition = ModelCondition.Value.parse(context: context, expr: argument.expression)
            case "additionalConditions":
                if let array = argument.expression.array?.elements {
                    for element in array {
                        if let tuple = element.expression.tuple?.elements {
                            var joiningOperator:ModelCondition.JoiningOperator? = nil
                            var condition:ModelCondition.Value? = nil
                            for (i, t) in tuple.enumerated() {
                                switch i {
                                case 0: // join operator
                                    if let s = t.expression.memberAccess?.declName.baseName.text {
                                        joiningOperator = .init(rawValue: s)
                                    }
                                case 1: // condition
                                    condition = ModelCondition.Value.parse(context: context, expr: t.expression)
                                default:
                                    break
                                }
                            }
                            if let joiningOperator, let condition {
                                additionalConditions.append((joiningOperator, condition))
                            }
                        }
                    }
                }
            default:
                break
            }
        }
        guard let name, let firstCondition else {
            context.diagnose(Diagnostic(node: expr, message: DiagnosticMsg.failedToParseModelCondition()))
            return nil
        }
        return ModelCondition(name: name, firstCondition: firstCondition, additionalConditions: additionalConditions)
    }
}
extension ModelCondition.Value {
    static func parse(
        context: some MacroExpansionContext,
        expr: ExprSyntax
    ) -> Self? {
        guard let functionCall = expr.functionCall,
                (functionCall.calledExpression.declReference?.baseName.text == "Value"
                || functionCall.calledExpression.memberAccess?.declName.baseName.text == "init")
        else {
            context.diagnose(Diagnostic(node: expr, message: DiagnosticMsg.failedToParseModelConditionValue()))
            return nil
        }
        var field:String? = nil
        var `operator`:ModelCondition.Operator? = nil
        var value:String? = nil
        for argument in functionCall.arguments {
            switch argument.label?.text {
            case "field":
                field = argument.expression.stringLiteral?.text
            case "operator":
                if let s = argument.expression.memberAccess?.declName.baseName.text {
                    `operator` = ModelCondition.Operator(rawValue: s)
                }
            case "value":
                value = argument.expression.stringLiteral?.text
            default:
                break
            }
        }
        guard let field, let `operator`, let value else {
            context.diagnose(Diagnostic(node: expr, message: DiagnosticMsg.failedToParseModelConditionValue()))
            return nil
        }
        return Self(field: field, operator: `operator`, value: value)
    }
}

// MARK: Parse model revision
extension ModelRevision {
    struct Compiled {
        let expr:ExprSyntax
        let version:(major: Int, minor: Int, patch: Int)
        let addedFields:[Field.Compiled]
        let updatedFields:[Field.Compiled]
        let removedFields:[(expr: ExprSyntax, name: String)]
    }
    static func parse(
        context: some MacroExpansionContext,
        expr: ExprSyntax
    ) -> Compiled? {
        guard let functionCall = expr.functionCall,
                (functionCall.calledExpression.declReference?.baseName.text == "ModelRevision"
                || functionCall.calledExpression.memberAccess?.declName.baseName.text == "init")
        else {
            context.diagnose(Diagnostic(node: expr, message: DiagnosticMsg.failedToParseModelRevision()))
            return nil
        }
        var version:(major: Int, minor: Int, patch: Int) = (0, 0, 0)
        var addedFields = [ModelRevision.Field.Compiled]()
        var updatedFields = [ModelRevision.Field.Compiled]()
        var removedFields = [(expr: ExprSyntax, name: String)]()
        for argument in functionCall.arguments {
            switch argument.label?.text {
            case "version":
                let tuple = argument.expression.tuple!.elements
                for (i, element) in tuple.enumerated() {
                    switch i {
                    case 0: version.major = element.expression.integer()!
                    case 1: version.minor = element.expression.integer()!
                    case 2: version.patch = element.expression.integer()!
                    default: break
                    }
                }
            case "addedFields":
                addedFields = parseDictionaryString(context: context, expr: argument.expression)
            case "updatedFields":
                updatedFields = parseDictionaryString(context: context, expr: argument.expression)
            case "removedFields":
                if let values:[(ExprSyntax, String)] = argument.expression.array?.elements.compactMap({
                    guard let value = $0.expression.stringLiteral?.text else { return nil }
                    return ($0.expression, value)
                }) {
                    removedFields = values
                }
            default:
                break
            }
        }
        return .init(expr: expr, version: version, addedFields: addedFields, updatedFields: updatedFields, removedFields: removedFields)
    }
    private static func parseDictionaryString(
        context: some MacroExpansionContext,
        expr: ExprSyntax
    ) -> [ModelRevision.Field.Compiled] {
        guard let array = expr.array?.elements else { return [] }
        var fields = [ModelRevision.Field.Compiled]()
        for element in array {
            if let field = ModelRevision.Field.parse(context: context, expr: element.expression) {
                fields.append(field)
            }
        }
        return fields
    }
}

// MARK: Parse field
extension ModelRevision.Field {
    struct Compiled {
        let expr:ExprSyntax
        let name:String
        var constraints:[Constraint] = [.notNull]
        var postgresDataType:PostgresDataType? = nil
        var defaultValue:String? = nil
    }
    static func parse(
        context: some MacroExpansionContext,
        expr: ExprSyntax
    ) -> Compiled? {
        guard let functionCall = expr.functionCall else {
            context.diagnose(Diagnostic(node: expr, message: DiagnosticMsg.failedToParseModelRevisionField()))
            return nil
        }
        var name:String? = nil
        var constraints:[ModelRevision.Field.Constraint] = [.notNull]
        var postgresDataType:PostgresDataType? = nil
        var defaultValue:String? = nil
        for arg in functionCall.arguments {
            switch arg.label?.text {
            case "name":
                name = arg.expression.stringLiteral?.text
            case "constraints":
                if let array = arg.expression.array?.elements {
                    constraints = array.compactMap({
                        .parse(context: context, expr: $0.expression)
                    })
                } else {
                    constraints = []
                }
            case "postgresDataType":
                if let s = arg.expression.memberAccess?.declName.baseName.text {
                    postgresDataType = .init(rawValue: s)
                } else if var s = arg.expression.functionCall?.description {
                    s.removeFirst()
                    postgresDataType = .init(rawValue: s)
                }
            case "defaultValue":
                defaultValue = arg.expression.stringLiteral?.text ?? arg.expression.as(BooleanLiteralExprSyntax.self)?.literal.text ?? arg.expression.integerLiteral?.literal.text
            default:
                break
            }
        }
        guard let name else {
            context.diagnose(Diagnostic(node: expr, message: DiagnosticMsg.failedToParseModelRevisionField()))
            return nil
        }
        return .init(expr: expr, name: name, constraints: constraints, postgresDataType: postgresDataType, defaultValue: defaultValue)
    }
}

// MARK: Parse field constraint
extension ModelRevision.Field.Constraint {
    static func parse(
        context: some MacroExpansionContext,
        expr: ExprSyntax
    ) -> Self? {
        guard let member = expr.memberAccess else {
            context.diagnose(Diagnostic(node: expr, message: DiagnosticMsg.failedToParseModelRevisionFieldConstraint()))
            return nil
        }
        switch member.declName.baseName.text {
        case "notNull":
            return .notNull
        case "check":
            return nil // TODO: fix
        case "unique":
            return .unique
        case "nullsNotDistinct":
            return .nullsNotDistinct
        case "primaryKey":
            return .primaryKey
        case "references":
            return nil // TODO: fix
        default:
            return nil
        }
    }
}