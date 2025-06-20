
import ModelUtilities
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

extension ModelMacro {
    static func preparedStatements(
        context: some MacroExpansionContext,
        structureName: String,
        supportedDatabases: Set<DatabaseType>,
        schema: String,
        selectFilters: [(fields: [String], condition: ModelCondition)],
        fields: [ModelRevision.Field.Compiled]
    ) -> String {
        var string = ""
        if supportedDatabases.contains(.postgreSQL) {
            string += postgresPreparedStatements(schema: schema, selectFilters: selectFilters, fields: fields)
        }
        return string
    }
}

// MARK: Postgres
extension ModelMacro {
    private static func postgresPreparedStatements(
        schema: String,
        selectFilters: [(fields: [String], condition: ModelCondition)],
        fields: [ModelRevision.Field.Compiled]
    ) -> String {
        let latestFieldNames = fields.map { $0.name }
        let latestFieldNamesJoined = latestFieldNames.joined(separator: ", ")
        let insertSQL = "INSERT INTO \(schema) (\(latestFieldNamesJoined)) VALUES (\(fields.enumerated().map({ "$\($0.offset+1)" }).joined(separator: ", ")));"
        let selectAllSQL = "SELECT \(latestFieldNamesJoined) FROM \(schema);"
        let selectWithLimitAndOffsetSQL = "SELECT \(latestFieldNamesJoined) FROM \(schema) LIMIT $1 OFFSET $2;"
        var preparedStatements = [
            PreparedStatement(name: "insert", parameters: fields, returningFields: [], sql: insertSQL),
            .init(name: "selectAll", parameters: [], returningFields: fields, sql: selectAllSQL)
        ]
        preparedStatements.append(.init(
            name: "selectWithLimitAndOffset",
            parameters: [
                .init(expr: ExprSyntax(StringLiteralExprSyntax(content: "limit")), name: "limit", postgresDataType: .integer),
                .init(expr: ExprSyntax(StringLiteralExprSyntax(content: "offset")), name: "offset", postgresDataType: .integer)
            ],
            returningFields: fields,
            sql: selectWithLimitAndOffsetSQL
        ))

        for (selectFields, condition) in selectFilters {
            let sql = "SELECT \(selectFields.joined(separator: ", ")) FROM \(schema) WHERE " + condition.sql + ";"
            var selectFieldsAndDataTypes = [ModelRevision.Field.Compiled]()
            for field in selectFields {
                if let target = fields.first(where: { $0.name == field }) {
                    selectFieldsAndDataTypes.append(target)
                } else {
                    // TODO: show compiler diagnostic
                    continue
                }
            }
            preparedStatements.append(.init(name: "selectAllWhere_" + condition.name, parameters: [], returningFields: selectFieldsAndDataTypes, sql: sql))
        }

        var preparedStatementsString = "public enum PostgresPreparedStatements {"
        for statement in preparedStatements {
            preparedStatementsString += postgresPreparedStatement(statement: statement, schema: schema)
        }
        preparedStatementsString += "\n    }"
        return preparedStatementsString
    }
    private static func postgresPreparedStatement(
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
        return "\n        public static let \(statement.name) = \(postgresPreparedStatement)"
    }
}