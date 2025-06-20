
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
        var revisions = [ModelRevision]()
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
                    revisions = child.expression.array?.elements.compactMap({ ModelRevision.parse(expr: $0.expression) }) ?? []
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
                                        condition = ModelCondition.parse(expr: t.expression)
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

        var latestFields = [ModelRevision.Field]()
        var latestFieldKeys = Set<String>()
        for revision in revisions {
            for field in revision.addedFields {
                if !latestFieldKeys.contains(field.name) {
                    latestFields.append(field)
                }
                latestFieldKeys.insert(field.name)
            }
            for field in revision.updatedFields {
                if latestFieldKeys.contains(field.name), let index = latestFields.firstIndex(where: { $0.name == field.name }) {
                    latestFields[index].postgresDataType = field.postgresDataType
                } else {
                    // TODO: show compiler diagnostic
                }
            }
            for field in revision.removedFields {
                if latestFieldKeys.contains(field), let index = latestFields.firstIndex(where: { $0.name == field }) {
                    latestFields.remove(at: index)
                } else {
                    // TODO: show compiler diagnostic
                }
                latestFieldKeys.remove(field)
            }
        }
        members.append(preparedStatements(structureName: structureName, supportedDatabases: supportedDatabases, schema: schema, selectFilters: selectFilters, fields: latestFields))
        members.append(migrations(structureName: structureName, supportedDatabases: supportedDatabases, schema: schema, revisions: revisions))
        members.append(compileSafety(structureName: structureName, fields: latestFields))
        let content = members.map({ .init(stringLiteral: "    " + $0 + "\n") }).joined()
        return try [
            .init(.init(stringLiteral: "extension \(structureName) {\n\(content)\n}"))
        ]
    }
}

// MARK: Prepared statements
extension ModelMacro {
    static func preparedStatements(
        structureName: String,
        supportedDatabases: Set<DatabaseType>,
        schema: String,
        selectFilters: [(fields: [String], condition: ModelCondition)],
        fields: [ModelRevision.Field]
    ) -> String {
        let latestFieldNames = fields.map { $0.name }
        let latestFieldNamesJoined = latestFieldNames.joined(separator: ", ")
        let insertSQL = "INSERT INTO \(schema) (\(latestFieldNamesJoined)) VALUES (\(fields.enumerated().map({ "$\($0.offset+1)" }).joined(separator: ", ")));"
        let selectAllSQL = "SELECT \(latestFieldNamesJoined) FROM \(schema);"
        let selectWithLimitAndOffsetSQL = "SELECT \(latestFieldNamesJoined) FROM \(schema) LIMIT $1 OFFSET $2;"
        var preparedStatements = [
            PreparedStatement(name: "Insert", parameters: fields, returningFields: [], sql: insertSQL),
            .init(name: "SelectAll", parameters: [], returningFields: fields, sql: selectAllSQL)
        ]
        preparedStatements.append(.init(
            name: "SelectWithLimitAndOffset",
            parameters: [
                .init(name: "limit", postgresDataType: .integer),
                .init(name: "offset", postgresDataType: .integer)
            ],
            returningFields: fields,
            sql: selectWithLimitAndOffsetSQL
        ))

        for (selectFields, condition) in selectFilters {
            let sql = "SELECT \(selectFields.joined(separator: ", ")) FROM \(schema) WHERE " + condition.sql + ";"
            var selectFieldsAndDataTypes = [ModelRevision.Field]()
            for field in selectFields {
                if let target = fields.first(where: { $0.name == field }) {
                    selectFieldsAndDataTypes.append(target)
                } else {
                    continue
                }
            }
            preparedStatements.append(.init(name: "SelectAllWhere_" + condition.name, parameters: [], returningFields: selectFieldsAndDataTypes, sql: sql))
        }

        var preparedStatementsString = "public enum PreparedStatements {"
        for statement in preparedStatements {
            if supportedDatabases.contains(.postgreSQL) {
                preparedStatementsString += getPostgresPreparedStatement(statement: statement, schema: schema)
            }
        }
        preparedStatementsString += "\n    }"
        return preparedStatementsString
    }
    private static func getPostgresPreparedStatement(
        statement: PreparedStatement,
        schema: String
    ) -> String {
        let name = schema + "_" + statement.name.lowercased()
        var parameterSwiftDataTypes = [String]()
        var parameterPostgresDataTypes = [String]()
        for param in statement.parameters {
            if let dataType = param.postgresDataType {
                parameterSwiftDataTypes.append(dataType.swiftDataType)
                parameterPostgresDataTypes.append(dataType.name)
            }
        }
        let subtype:String
        let genericParameters:String
        if parameterSwiftDataTypes.isEmpty {
            subtype = "Parameterless"
            genericParameters = ""
        } else {
            subtype = ""
            genericParameters = "<" + parameterSwiftDataTypes.joined(separator: ", ") + ">"
        }
        var postgresPreparedStatement = "Postgres\(subtype)PreparedStatement\(genericParameters)"
        let sql = "PREPARE \(name)" + (parameterSwiftDataTypes.isEmpty ? "" : "(\(parameterPostgresDataTypes.joined(separator: ", ")))") + " AS \(statement.sql)"
        postgresPreparedStatement += "(name: \"\(name)\", sql: \"\(sql)\")"
        return "\n        public static let postgreSQL\(statement.name) = \(postgresPreparedStatement)"
    }
}

// MARK: Migrations
extension ModelMacro {
    static func migrations(
        structureName: String,
        supportedDatabases: Set<DatabaseType>,
        schema: String,
        revisions: [ModelRevision]
    ) -> String {
        var migrations = [(name: String?, version: (Int, Int, Int), sql: String)]()
        var migrationsString = "public enum Migrations {\n"

        if !revisions.isEmpty {
            var sortedRevisions = revisions.sorted(by: { $0.version < $1.version })
            let initialRevision = sortedRevisions.removeFirst()
            if supportedDatabases.contains(.postgreSQL) {
                let addedFieldsString:String = initialRevision.addedFields.compactMap({
                    guard let dataType = $0.postgresDataType?.name else {
                        // TODO: show compiler diagnostic
                        return nil
                    }
                    let constraintsString = $0.constraints.map({ $0.name }).joined(separator: " ")
                    return $0.name + " " + dataType + (constraintsString.isEmpty ? "" : " " + constraintsString)
                }).joined(separator: ", ")
                let createTableSQL = "CREATE TABLE IF NOT EXISTS " + schema + " (" + addedFieldsString + ");"
                migrations.append(("postgresCreate", initialRevision.version, createTableSQL))
            }

            for revision in sortedRevisions {
            }

            migrationsString += migrations.map({ (name, version, sql) in
                return "        @inlinable public static var " + (name ?? "v\(version.0)_\(version.1)_\(version.2)") + ": String { \"" + sql + "\" }"
            }).joined(separator: "\n")
        }
        migrationsString += "\n    }"
        return migrationsString
    }
}

// MARK: Compile safety
extension ModelMacro {
    static func compileSafety(structureName: String, fields: [ModelRevision.Field]) -> String {
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
        let parameters:[ModelRevision.Field]
        let returningFields:[ModelRevision.Field]
        let sql:String
    }
}

// MARK: Parse model condition
extension ModelCondition {
    static func parse(expr: ExprSyntax) -> Self? {
        guard let functionCall = expr.functionCall,
                functionCall.calledExpression.declReference?.baseName.text == "ModelCondition" else {
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
                firstCondition = ModelCondition.Value.parse(expr: argument.expression)
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
                                    condition = ModelCondition.Value.parse(expr: t.expression)
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
        guard let name, let firstCondition else { return nil }
        return ModelCondition(name: name, firstCondition: firstCondition, additionalConditions: additionalConditions)
    }
}
extension ModelCondition.Value {
    static func parse(expr: ExprSyntax) -> Self? {
        guard let functionCall = expr.functionCall,
                (functionCall.calledExpression.declReference?.baseName.text == "Value"
                || functionCall.calledExpression.memberAccess?.declName.baseName.text == "init")
        else {
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
        guard let field, let `operator`, let value else { return nil }
        return Self(field: field, operator: `operator`, value: value)
    }
}

// MARK: Parse model revision
extension ModelRevision {
    static func parse(expr: ExprSyntax) -> Self? {
        guard let functionCall = expr.functionCall,
                (functionCall.calledExpression.declReference?.baseName.text == "ModelRevision"
                || functionCall.calledExpression.memberAccess?.declName.baseName.text == "init")
        else {
            return nil
        }
        var version:(major: Int, minor: Int, patch: Int) = (0, 0, 0)
        var addedFields = [ModelRevision.Field]()
        var updatedFields = [ModelRevision.Field]()
        var removedFields = Set<String>()
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
                addedFields = parseDictionaryString(expr: argument.expression)
            case "updatedFields":
                updatedFields = parseDictionaryString(expr: argument.expression)
            case "removedFields":
                if let values = argument.expression.array?.elements.compactMap({ $0.expression.stringLiteral?.text }) {
                    removedFields = Set(values)
                }
            default:
                break
            }
        }
        return Self(version: version, addedFields: addedFields, updatedFields: updatedFields, removedFields: removedFields)
    }
    private static func parseDictionaryString(expr: ExprSyntax) -> [ModelRevision.Field] {
        guard let array = expr.array?.elements else { return [] }
        var fields = [ModelRevision.Field]()
        for element in array {
            if let field = ModelRevision.Field.parse(expr: element.expression) {
                fields.append(field)
            }
        }
        return fields
    }
}

// MARK: Parse field
extension ModelRevision.Field {
    static func parse(expr: ExprSyntax) -> Self? {
        guard let functionCall = expr.functionCall else { return nil }
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
                    constraints = array.compactMap({ ModelRevision.Field.Constraint.parse(expr: $0.expression) })
                } else {
                    constraints = []
                }
                break
            case "postgresDataType":
                if let s = arg.expression.memberAccess?.declName.baseName.text {
                    postgresDataType = .init(rawValue: s)
                } else if var s = arg.expression.functionCall?.description {
                    s.removeFirst()
                    postgresDataType = .init(rawValue: s)
                }
            case "defaultValue":
                defaultValue = arg.expression.stringLiteral?.text
            default:
                break
            }
        }
        if let name {
            return .init(name: name, constraints: constraints, postgresDataType: postgresDataType, defaultValue: defaultValue)
        }
        return nil
    }
}

// MARK: Parse field constraint
extension ModelRevision.Field.Constraint {
    static func parse(expr: ExprSyntax) -> Self? {
        guard let member = expr.memberAccess else { return nil }
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