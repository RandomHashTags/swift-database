
import ModelUtilities
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

enum ModelMacro {
    struct ModelConstruct {
        let name:String

        let isStruct:Bool

        var isClass: Bool {
            !isStruct
        }
    }
}

extension ModelMacro: ExtensionMacro {
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let construct:ModelConstruct
        if let s = declaration.as(StructDeclSyntax.self) {
            construct = .init(name: s.name.text, isStruct: true)
        } else if let c = declaration.as(ClassDeclSyntax.self) {
            construct = .init(name: c.name.text, isStruct: false)
        } else {
            return []
        }
        guard let args = node.arguments?.children(viewMode: .all) else {
            return []
        }

        var supportedDatabases = Set<DatabaseType>()
        var schema:String? = "public"
        var schemaAlias:String? = nil
        var initialTable:String? = nil
        var selectFilters = [(fields: [String], condition: ModelCondition)]()
        var revisions = [ModelRevision.Compiled]()
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
                    schema = child.expression.legalStringliteralText(context: context)
                case "schemaAlias":
                    schemaAlias = child.expression.legalStringliteralText(context: context)
                case "table":
                    initialTable = child.expression.legalStringliteralText(context: context)
                case "revisions":
                    var previousTableName:String? = initialTable
                    var version = 0
                    revisions = child.expression.array?.elements.compactMap({
                        ModelRevision.parse(
                            context: context,
                            expr: $0.expression,
                            previousTableName: &previousTableName,
                            version: &version
                        )
                    }) ?? []
                case "selectFilters":
                    if let array = child.expression.array?.elements {
                        for element in array {
                            if let tuple = element.expression.tuple {
                                var fields:[String]? = nil
                                var condition:ModelCondition? = nil
                                for (i, t) in tuple.elements.enumerated() {
                                    switch i {
                                    case 0:
                                        fields = t.expression.array?.elements.compactMap({ $0.expression.legalStringliteralText(context: context) })
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
        guard let schema, let initialTable else { return [] }
        var members = [String]()
        members.append("@inlinable public static var schema: String { \"\(schema)\" }")
        members.append("@inlinable public static var alias: String? { \(schemaAlias == nil ? "nil" : "\"\(schemaAlias!)\"") }")

        var convenienceLogicString = ""
        if let initialVersion = revisions.first?.version {
            let lastTableName = revisions.last!.tableName
            members.append("@inlinable public static var table: String { \"\(lastTableName)\" }")

            guard let latestFields = validateRevisions(
                context: context,
                initialVersion: initialVersion,
                revisions: &revisions
            ) else {
                return []
            }
            members.append(preparedStatements(
                context: context,
                supportedDatabases: supportedDatabases,
                schema: schema,
                schemaAlias: schemaAlias,
                table: lastTableName,
                selectFilters: selectFilters,
                fields: latestFields
            ))
            members.append(migrations(
                context: context,
                supportedDatabases: supportedDatabases,
                schema: schema,
                schemaAlias: schemaAlias,
                revisions: revisions
            ))
            members.append(compileSafety(construct: construct, fields: latestFields))

            convenienceLogicString = convenienceLogic(context: context, construct: construct, supportedDatabases: supportedDatabases, schema: schema, fields: latestFields)
        }
        let content = members.map({ .init(stringLiteral: "    " + $0 + "\n") }).joined()
        return try [
            .init(.init(stringLiteral: "extension \(construct.name) {\n\(content)\n}")),
            .init(.init(stringLiteral: convenienceLogicString))
        ]
    }
}

// MARK: Validate revisions
extension ModelMacro {
    static func validateRevisions(
        context: some MacroExpansionContext,
        initialVersion: Int,
        revisions: inout [ModelRevision.Compiled]
    ) -> [ModelRevision.Field.Compiled]? {
        var latestFields = [ModelRevision.Field.Compiled]()
        var latestFieldKeys = Set<String>()
        for indice in revisions.indices {
            let revision = revisions[indice]
            let isInitial = revision.version == initialVersion
            var validRevision = ModelRevision.Compiled(
                expr: revision.expr,
                tableName: revision.tableName,
                version: revision.version,
                addedFields: [],
                updatedFields: [],
                renamedFields: [],
                removedFields: []
            )
            for field in revision.addedFields {
                if latestFieldKeys.contains(field.columnName) {
                    context.diagnose(DiagnosticMsg.fieldAlreadyExists(expr: field.expr))
                    return nil
                } else {
                    if !isInitial && field.constraints.contains(.notNull) && field.defaultValue == nil {
                        context.diagnose(DiagnosticMsg.notNullFieldMissingDefaultValue(expr: field.expr))
                        return nil
                    }
                    latestFields.append(field)
                }
                latestFieldKeys.insert(field.columnName)
                validRevision.addedFields.append(field)
            }
            for field in revision.updatedFields {
                if let index = latestFields.firstIndex(where: { $0.columnName == field.columnName }) {
                    if latestFields[index].postgresDataType == field.postgresDataType {
                        context.diagnose(DiagnosticMsg.cannotUpdateFieldWithIdenticalDataType(expr: field.expr))
                    } else {
                        latestFields[index].variableName = field.variableName
                        latestFields[index].postgresDataType = field.postgresDataType
                        validRevision.updatedFields.append(field)
                    }
                } else {
                    context.diagnose(DiagnosticMsg.cannotUpdateFieldThatDoesntExist(expr: field.expr))
                }
            }
            for field in revision.removedFields {
                if let index = latestFields.firstIndex(where: { $0.columnName == field.name }) {
                    latestFields.remove(at: index)
                    latestFieldKeys.remove(field.name)
                    validRevision.removedFields.append(field)
                } else {
                    context.diagnose(DiagnosticMsg.cannotRemoveFieldThatDoesntExist(expr: field.expr))
                }
            }
            for field in revision.renamedFields {
                if let index = latestFields.firstIndex(where: { $0.columnName == field.from }) {
                    if latestFields.firstIndex(where: { $0.columnName == field.to }) == nil {
                        latestFields[index].columnName = field.to
                        latestFields[index].variableName = field.to
                        latestFieldKeys.remove(field.from)
                        latestFieldKeys.insert(field.to)
                        validRevision.renamedFields.append(field)
                    } else {
                        context.diagnose(DiagnosticMsg.cannotRenameFieldToExistingField(field: field))
                        return nil
                    }
                } else {
                    context.diagnose(DiagnosticMsg.cannotRenameFieldThatDoesntExist(expr: field.expr))
                }
            }
            // make sure a primary key exists after applying this revision
            if latestFields.first(where: { $0.constraints.contains(.primaryKey) }) == nil {
                context.diagnose(Diagnostic(node: revision.expr, message: DiagnosticMsg.missingPrimaryKey()))
                return nil
            }
            revisions[indice] = validRevision
        }
        return latestFields
    }
}

// MARK: Compile safety
extension ModelMacro {
    static func compileSafety(
        construct: ModelConstruct,
        fields: [ModelRevision.Field.Compiled]
    ) -> String {
        let constructName = construct.name
        var safetyString = "enum Safety {"
        var fields = fields
        if let pkIndex = fields.firstIndex(where: { $0.constraints.contains(.primaryKey) }) {
            fields.remove(at: pkIndex)
        }
        for field in fields {
            if let dataType = field.postgresDataType?.swiftDataType {
                safetyString += "\n        var \(field.variableName): KeyPath<\(constructName), \(dataType)\(field.isRequired ? "" : "?")> { \\\(constructName).\(field.variableName) }"
            } else {
                // TODO: show compiler diagnostic
            }
        }
        safetyString += "\n}"
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
        guard let functionCall = expr.functionCall else {
            context.diagnose(DiagnosticMsg.expectedFunctionCallExpr(expr: expr))
            return nil
        }
        var name:String? = nil
        var firstCondition:ModelCondition.Value? = nil
        var additionalConditions = [(joiningOperator: JoiningOperator, condition: Value)]()
        for arg in functionCall.arguments {
            switch arg.label?.text {
            case "name":
                name = arg.expression.legalStringliteralText(context: context)
            case "firstCondition":
                firstCondition = ModelCondition.Value.parse(context: context, expr: arg.expression)
            case "additionalConditions":
                if let array = arg.expression.array?.elements {
                    for element in array {
                        if let tuple = element.expression.tuple?.elements {
                            var joiningOperator:ModelCondition.JoiningOperator? = nil
                            var condition:ModelCondition.Value? = nil
                            for (i, t) in tuple.enumerated() {
                                switch i {
                                case 0: // join operator
                                    if let s = t.expression.memberAccess?.declName.baseName.text {
                                        joiningOperator = .init(rawValue: s)
                                    } else {
                                        context.diagnose(DiagnosticMsg.expectedMemberAccessExpr(expr: t.expression))
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
                } else {
                    context.diagnose(DiagnosticMsg.expectedArrayExpr(expr: arg.expression))
                }
            default:
                break
            }
        }
        guard let name, let firstCondition else { return nil }
        return ModelCondition(name: name, firstCondition: firstCondition, additionalConditions: additionalConditions)
    }
}
extension ModelCondition.Value {
    static func parse(
        context: some MacroExpansionContext,
        expr: ExprSyntax
    ) -> Self? {
        guard let functionCall = expr.functionCall else {
            context.diagnose(DiagnosticMsg.expectedFunctionCallExpr(expr: expr))
            return nil
        }
        var field:String? = nil
        var `operator`:ModelCondition.Operator? = nil
        var value:String? = nil
        for arg in functionCall.arguments {
            switch arg.label?.text {
            case "field":
                field = arg.expression.legalStringliteralText(context: context)
            case "operator":
                if let s = arg.expression.memberAccess?.declName.baseName.text {
                    `operator` = ModelCondition.Operator(rawValue: s)
                } else {
                    context.diagnose(DiagnosticMsg.expectedMemberAccessExpr(expr: arg.expression))
                }
            case "value":
                value = arg.expression.legalStringliteralText(context: context)
            default:
                break
            }
        }
        guard let field, let `operator`, let value else { return nil }
        return Self(field: field, operator: `operator`, value: value)
    }
}

// MARK: Parse model revision
extension ModelRevision {
    struct Compiled {
        let expr:ExprSyntax
        let tableName:String
        let version:Int
        var addedFields:[Field.Compiled]
        var updatedFields:[Field.Compiled]
        var renamedFields:[(expr: ExprSyntax, from: String, to: String)]
        var removedFields:[(expr: ExprSyntax, name: String)]
    }
    static func parse(
        context: some MacroExpansionContext,
        expr: ExprSyntax,
        previousTableName: inout String?,
        version: inout Int
    ) -> Compiled? {
        guard let functionCall = expr.functionCall else {
            context.diagnose(DiagnosticMsg.expectedFunctionCallExpr(expr: expr))
            return nil
        }
        var addedFields = [ModelRevision.Field.Compiled]()
        var updatedFields = [ModelRevision.Field.Compiled]()
        var renamedFields = [(ExprSyntax, String, String)]()
        var removedFields = [(expr: ExprSyntax, name: String)]()
        for arg in functionCall.arguments {
            switch arg.label?.text {
            case "newTableName":
                previousTableName = arg.expression.legalStringliteralText(context: context)
            case "addedFields":
                addedFields = parseDictionaryString(context: context, expr: arg.expression)
            case "updatedFields":
                updatedFields = parseDictionaryString(context: context, expr: arg.expression)
            case "renamedFields":
                renamedFields = parseRenamedFields(context: context, expr: arg.expression)
            case "removedFields":
                if let values:[(ExprSyntax, String)] = arg.expression.array?.elements.compactMap({
                    guard let value = $0.expression.legalStringliteralText(context: context) else {
                        return nil
                    }
                    return ($0.expression, value)
                }) {
                    removedFields = values
                } else {
                    context.diagnose(DiagnosticMsg.expectedArrayExpr(expr: arg.expression))
                }
            default:
                break
            }
        }
        guard let previousTableName else {
            context.diagnose(DiagnosticMsg.revisionMissingTableName(expr: expr))
            return nil
        }
        version += 1
        return .init(
            expr: expr,
            tableName: previousTableName,
            version: version,
            addedFields: addedFields,
            updatedFields: updatedFields,
            renamedFields: renamedFields,
            removedFields: removedFields
        )
    }
    private static func parseDictionaryString(
        context: some MacroExpansionContext,
        expr: ExprSyntax
    ) -> [ModelRevision.Field.Compiled] {
        guard let array = expr.array?.elements else {
            context.diagnose(DiagnosticMsg.expectedArrayExpr(expr: expr))
            return []
        }
        var fields = [ModelRevision.Field.Compiled]()
        for element in array {
            if let field = ModelRevision.Field.parse(context: context, expr: element.expression) {
                fields.append(field)
            }
        }
        return fields
    }
    private static func parseRenamedFields(
        context: some MacroExpansionContext,
        expr: ExprSyntax
    ) -> [(ExprSyntax, String, String)] {
        guard let array = expr.array?.elements else {
            context.diagnose(DiagnosticMsg.expectedArrayExpr(expr: expr))
            return []
        }
        return array.compactMap({
            guard let tuple = $0.expression.tuple?.elements,
                let from = tuple.first?.expression.legalStringliteralText(context: context),
                let to = tuple.last?.expression.legalStringliteralText(context: context)
            else {
                return nil
            }
            return ($0.expression, from, to)
        })
    }
}