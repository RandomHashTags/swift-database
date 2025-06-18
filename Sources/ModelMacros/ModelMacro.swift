
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
        var revisions = [CompiledModelRevision]()
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
                    revisions = child.expression.array?.elements.compactMap({ CompiledModelRevision.parse(expr: $0.expression) }) ?? []
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

        var latestFields = [(name: String, dataType: String)]()
        var latestFieldKeys = Set<String>()
        for revision in revisions {
            for (field, dataType) in revision.addedFields {
                if !latestFieldKeys.contains(field) {
                    latestFields.append((field, dataType))
                }
                latestFieldKeys.insert(field)
            }
            for (field, newDataType) in revision.updatedFields {
                if latestFieldKeys.contains(field), let index = latestFields.firstIndex(where: { $0.name == field }) {
                    latestFields[index].dataType = newDataType
                } else {
                    // show compiler diagnostic
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
        members.append(migrations(structureName: structureName, schema: schema, revisions: revisions))
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
        fields: [(name: String, dataType: String)]
    ) -> String {
        let latestFieldNames = fields.map { $0.name }
        let latestFieldNamesJoined = latestFieldNames.joined(separator: ", ")
        let insertSQL = "INSERT INTO \(schema) (\(latestFieldNamesJoined)) VALUES (\(fields.enumerated().map({ "$\($0.offset+1)" }).joined(separator: ", ")));"
        let selectAllSQL = "SELECT \(latestFieldNamesJoined) FROM \(schema);"
        var preparedStatements = [
            PreparedStatement(name: "Insert", parameters: fields, returningFields: [], sql: insertSQL),
            .init(name: "SelectAll", parameters: [], returningFields: fields, sql: selectAllSQL)
        ]

        for (selectFields, condition) in selectFilters {
            let sql = "SELECT \(selectFields.joined(separator: ", ")) FROM \(schema) WHERE " + condition.sql + ";"
            var selectFieldsAndDataTypes = [(name: String, dataType: String)]()
            for field in selectFields {
                if let (_, dataType) = fields.first(where: { $0.name == field }) {
                    selectFieldsAndDataTypes.append((field, dataType))
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
        let parameterDataTypes = statement.parameters.map { $0.dataType }
        let parameterDataTypesJoined = parameterDataTypes.joined(separator: ", ")
        let subtype:String
        let genericParameters:String
        if parameterDataTypesJoined.isEmpty {
            subtype = "Parameterless"
            genericParameters = ""
        } else {
            subtype = ""
            genericParameters = "<" + parameterDataTypesJoined + ">"
        }
        var postgresPreparedStatement = "Postgres\(subtype)PreparedStatement\(genericParameters)"
        let sql = "PREPARE \(name)" + (statement.parameters.isEmpty ? "" : "(\(parameterDataTypesJoined))") + " AS \(statement.sql)"
        postgresPreparedStatement += "(name: \"\(name)\", sql: \"\(sql)\")"
        return "\n        public static let postgreSQL\(statement.name) = \(postgresPreparedStatement)"
    }
}

// MARK: Migrations
extension ModelMacro {
    static func migrations(
        structureName: String,
        schema: String,
        revisions: [CompiledModelRevision]
    ) -> String {
        var migrations = [(name: String?, version: (Int, Int, Int), sql: String)]()
        var migrationsString = "public enum Migrations {\n"

        if !revisions.isEmpty {
            var sortedRevisions = revisions.sorted(by: { $0.version < $1.version })
            let initialRevision = sortedRevisions.removeFirst()
            let createTableSQL = "CREATE TABLE IF NOT EXIST " + schema + " (" + initialRevision.addedFields.map({ $0.name + " " + $0.dataType + " NOT NULL" }).joined(separator: ", ") + ");"
            migrations.append(("create", initialRevision.version, createTableSQL))

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
    static func compileSafety(structureName: String, fields: [(name: String, dataType: String)]) -> String {
        var safetyString = "enum Safety {"
        for (field, _) in fields {
            safetyString += "\n        var \(field): AnyKeyPath { \\\(structureName).\(field) }"
        }
        safetyString += "\n    }"
        return safetyString
    }
}

// MARK: PreparedStatement
extension ModelMacro {
    struct PreparedStatement: Sendable {
        let name:String
        let parameters:[(name: String, dataType: String)]
        let returningFields:[(name: String, dataType: String)]
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

extension ModelMacro {
    struct CompiledModelRevision {
        let version:(major: Int, minor: Int, patch: Int)
        let addedFields:[(name: String, dataType: String)]
        let updatedFields:[(name: String, newDataType: String)]
        let removedFields:Set<String>
    }
}

// MARK: Parse model revision
extension ModelMacro.CompiledModelRevision {
    static func parse(expr: ExprSyntax) -> Self? {
        guard let functionCall = expr.functionCall,
                (functionCall.calledExpression.declReference?.baseName.text == "ModelRevision"
                || functionCall.calledExpression.memberAccess?.declName.baseName.text == "init")
        else {
            return nil
        }
        var version:(major: Int, minor: Int, patch: Int) = (0, 0, 0)
        var addedFields = [(String, String)]()
        var updatedFields = [(String, String)]()
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
    private static func parseDictionaryString(expr: ExprSyntax) -> [(name: String, dataType: String)] {
        guard let content = expr.dictionary?.content else { return [] }
        var dic = [(name: String, dataType: String)]()
        switch content {
        case .elements(let elements):
            for element in elements {
                if let key = element.key.stringLiteral?.text, let value = element.value.stringLiteral?.text {
                    dic.append((key, value))
                }
            }
        default:
            break
        }
        return dic
    }
}