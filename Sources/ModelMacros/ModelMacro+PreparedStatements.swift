
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
        var preparedStatements = [PreparedStatement]()
        let allFieldNamesJoined = fields.map { $0.name }.joined(separator: ", ")
        var insertFields = fields
        var primaryKeyField:ModelRevision.Field.Compiled! = nil
        if let primaryKeyFieldIndex = insertFields.firstIndex(where: { $0.constraints.contains(.primaryKey) }) {
            primaryKeyField = insertFields[primaryKeyFieldIndex]
            if primaryKeyField.postgresDataType == .serial || primaryKeyField.postgresDataType == .bigserial {
                insertFields.remove(at: primaryKeyFieldIndex)
            }
        }
        let insertFieldsJoined = insertFields.map { $0.name }.joined(separator: ", ")
        let insertSQL = "INSERT INTO \(schema) (\(insertFieldsJoined)) VALUES (\(insertFields.enumerated().map({ "$\($0.offset+1)" }).joined(separator: ", ")))"
        preparedStatements.append(.init(name: "insert", parameters: insertFields, returningFields: [], sql: insertSQL))

        if let primaryKeyField {
            let updateSQL = "UPDATE \(schema) SET " + insertFields.enumerated().map {
                $0.element.name + " = $\($0.offset+2)"
            }.joined(separator: ", ") + " WHERE \(primaryKeyField.name) = $1"
            preparedStatements.append(.init(name: "update", parameters: fields, returningFields: [], sql: updateSQL))
            
            for field in insertFields {
                if field != primaryKeyField {
                    let sql = "UPDATE \(schema) SET \(field.name) = $2 WHERE \(primaryKeyField.name) = $1"
                    preparedStatements.append(.init(name: "update\(field.formattedName)", parameters: [primaryKeyField, field], returningFields: [], sql: sql))
                }
            }

            let selectSQL = "SELECT \(allFieldNamesJoined) FROM \(schema) WHERE \(primaryKeyField.name) = $1"
            preparedStatements.append(.init(name: "select", parameters: [primaryKeyField], returningFields: fields, sql: selectSQL))
        }
        
        let selectAllSQL = "SELECT \(allFieldNamesJoined) FROM \(schema)"
        preparedStatements.append(.init(name: "selectAll", parameters: [], returningFields: fields, sql: selectAllSQL))

        let selectWithLimitAndOffsetSQL = "SELECT \(allFieldNamesJoined) FROM \(schema) LIMIT $1 OFFSET $2"
        preparedStatements.append(.init(
            name: "selectAllWithLimitAndOffset",
            parameters: [
                .init(expr: ExprSyntax(StringLiteralExprSyntax(content: "limit")), name: "limit", postgresDataType: .integer),
                .init(expr: ExprSyntax(StringLiteralExprSyntax(content: "offset")), name: "offset", postgresDataType: .integer)
            ],
            returningFields: fields,
            sql: selectWithLimitAndOffsetSQL
        ))
        for field in fields {
            let sql = "SELECT \(allFieldNamesJoined) FROM \(schema) WHERE \(field.name) = $1"
            let name = field.formattedName
            preparedStatements.append(.init(
                name: "selectAllWhere\(name)Equals",
                parameters: [
                    .init(expr: ExprSyntax(StringLiteralExprSyntax(content: "")), name: field.name, postgresDataType: field.postgresDataType)
                ],
                returningFields: fields, sql: sql
            ))
        }

        for (selectFields, condition) in selectFilters {
            let sql = "SELECT \(selectFields.joined(separator: ", ")) FROM \(schema) WHERE " + condition.sql
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
                let isRequired = param.isRequired
                parameterSwiftDataTypes.append(dataType.swiftDataType + (isRequired ? "" : "?"))
                parameterPostgresDataTypes.append(dataType.name)
            }
        }
        let subtype:String
        let genericParameters:String
        if parameterSwiftDataTypes.isEmpty {
            subtype = "Parameterless"
            genericParameters = ""
        } else {
            subtype = "Parameterized"
            genericParameters = "<" + parameterSwiftDataTypes.joined(separator: ", ") + ">"
        }
        var postgresPreparedStatement = "Postgres\(subtype)PreparedStatement\(genericParameters)"
        let sql = "PREPARE \(name)" + (parameterSwiftDataTypes.isEmpty ? "" : "(\(parameterPostgresDataTypes.joined(separator: ", ")))") + " AS \(statement.sql)"
        postgresPreparedStatement += "(name: \"\(name)\", sql: \"\(sql)\")"
        return "\n        public static let \(statement.name) = \(postgresPreparedStatement)"
    }
}