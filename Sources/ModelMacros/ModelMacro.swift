
import ModelUtilities
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

enum ModelMacro {
}

extension ModelMacro: MemberMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structure = declaration.as(StructDeclSyntax.self) else { return [] }
        guard let args = node.arguments?.children(viewMode: .all) else { return [] }

        var supportedDatabases = Set<DatabaseType>()
        var schema = ""
        var alias:String? = nil
        var revisions = [ModelRevision]()
        var members = [String]()
        for arg in args {
            if let child = arg.as(LabeledExprSyntax.self) {
                switch child.label?.text {
                case "supportedDatabases":
                    if let array = child.expression.as(ArrayExprSyntax.self)?.elements {
                        for element in array {
                            if let s = element.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text, let type = DatabaseType(rawValue: s) {
                                supportedDatabases.insert(type)
                            }
                        }
                    }
                case "schema":
                    schema = child.expression.as(StringLiteralExprSyntax.self)?.segments.description ?? ""
                case "alias":
                    alias = child.expression.as(StringLiteralExprSyntax.self)?.segments.description
                case "revisions":
                    revisions = child.expression.as(ArrayExprSyntax.self)?.elements.compactMap({ ModelRevision.parse(expr: $0.expression) }) ?? []
                default:
                    break
                }
            }
        }
        members.append("@inlinable public static var schema: String { \"\(schema)\" }")
        members.append("@inlinable public static var alias: String? { \(alias == nil ? "nil" : "\"\(alias!)\"") }")

        var preparedStatements = [PreparedStatement]()
        
        for revision in revisions {
            let insertSQL = "INSERT INTO \(schema) (\(revision.fields.map({ $0.name }).joined(separator: ", "))) VALUES (\(revision.fields.map({ _ in "?" }).joined(separator: ", ")))"
            preparedStatements.append(
                .init(name: "Insert", fields: revision.fields, sql: insertSQL)
            )
        }
        var preparedStatementsString = "public enum PreparedStatements {"

        for statement in preparedStatements {
            if supportedDatabases.contains(.postgreSQL) {
                let insertName = schema + "_insert"
                let fieldDataTypes = statement.fields.map { $0.dataType }
                var postgresPreparedStatement = "PostgresPreparedStatement<" + fieldDataTypes.joined(separator: ", ") + ">"
                postgresPreparedStatement += " { .init(name: \"\(insertName)\", fieldDataTypes: \(fieldDataTypes), sql: \"\(statement.sql)\") }"
                preparedStatementsString += "\n        @inlinable public static var postgreSQL\(statement.name): \(postgresPreparedStatement)"
            }
        }
        preparedStatementsString += "\n    }"
        members.append(preparedStatementsString)

        var migrations = [(version: (Int, Int, Int), sql: String)]()
        var migrationsString = "public enum Migrations {\n"
        migrationsString += migrations.map({ "public static var v\($0.version.0)_\($0.version.1)_\($0.version.2): String { \"\($0.sql)\" }" }).joined(separator: "\n")
        migrationsString += "\n}"
        members.append(migrationsString)

        return members.map({ .init(stringLiteral: "    " + $0 + "\n") })
    }
}

extension ModelMacro {
    struct PreparedStatement: Sendable {
        let name:String
        let fields:[(name: String, dataType: String)]
        let sql:String
    }
}

// MARK: Parse model revision
extension ModelRevision {
    static func parse(expr: ExprSyntax) -> Self? {
        if let functionCall = expr.as(FunctionCallExprSyntax.self) {
            if let decl = functionCall.calledExpression.as(DeclReferenceExprSyntax.self) {
                switch decl.baseName.text {
                case "ModelRevision":
                    var version:(major: Int, minor: Int, patch: Int) = (0, 0, 0)
                    var fields:[(name: String, dataType: String)] = []
                    for (argumentIndex, argument) in functionCall.arguments.enumerated() {
                        switch argumentIndex {
                        case 0: // version
                            let tuple = argument.expression.as(TupleExprSyntax.self)!.elements
                            for (i, element) in tuple.enumerated() {
                                switch i {
                                case 0: version.major = Int(element.expression.as(IntegerLiteralExprSyntax.self)!.literal.text)!
                                case 1: version.minor = Int(element.expression.as(IntegerLiteralExprSyntax.self)!.literal.text)!
                                case 2: version.patch = Int(element.expression.as(IntegerLiteralExprSyntax.self)!.literal.text)!
                                default: break
                                }
                            }
                        case 1: // parameters
                            let array = argument.expression.as(ArrayExprSyntax.self)!.elements
                            for element in array {
                                let tuple = element.expression.as(TupleExprSyntax.self)!.elements
                                var name:String? = nil
                                var dataType:String? = nil
                                for (i, element) in tuple.enumerated() {
                                    switch i {
                                    case 0: // name
                                        name = element.expression.as(StringLiteralExprSyntax.self)?.segments.description
                                    case 1: // dataType
                                        dataType = element.expression.as(StringLiteralExprSyntax.self)?.segments.description
                                    default:
                                        break
                                    }
                                    
                                }
                                if let name, let dataType {
                                    fields.append((name, dataType))
                                }
                            }
                        default:
                            break   
                        }
                    }
                    return ModelRevision(version: version, fields: fields)
                default:
                    break
                }
            }
        }
        return nil
    }
}