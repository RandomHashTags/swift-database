
import ModelUtilities
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

extension ModelMacro {
    static func preparedStatements(
        context: some MacroExpansionContext,
        supportedDatabases: Set<DatabaseType>,
        schema: String,
        schemaAlias: String?,
        table: String,
        selectFilters: [(fields: [String], condition: ModelCondition)],
        fields: [ModelRevision.Column.Compiled]
    ) -> String {
        var string = ""
        if supportedDatabases.contains(.postgreSQL) {
            string += postgresPreparedStatements(schema: schema, schemaAlias: schemaAlias, table: table, selectFilters: selectFilters, fields: fields)
        }
        return string
    }
}

// MARK: Postgres
extension ModelMacro {
    private static func postgresPreparedStatements(
        schema: String,
        schemaAlias: String?,
        table: String,
        selectFilters: [(fields: [String], condition: ModelCondition)],
        fields: [ModelRevision.Column.Compiled]
    ) -> String {
        let schemaTable = schema + "." + table
        var preparedStatements = [PreparedStatement]()
        let allColumnsJoined = fields.map { $0.columnName }.joined(separator: ", ")
        let insertableFields = fields.insertableFields
        let insertFieldsJoined = insertableFields.map { $0.columnName }.joined(separator: ", ")
        let insertSQL = "INSERT INTO \(schemaTable) (\(insertFieldsJoined)) VALUES (\(insertableFields.enumerated().map({ "$\($0.offset+1)" }).joined(separator: ", ")))"
        preparedStatements.append(.init(name: "insert", parameters: insertableFields, returnedColumns: [], sql: insertSQL))
        preparedStatements.append(.init(name: "insertReturning", parameters: insertableFields, returnedColumns: fields, sql: insertSQL + " RETURNING \(allColumnsJoined)"))

        if let primaryKeyField = fields.primaryKey {
            let updatableFields = fields.updatableFields
            let updateSQL = "UPDATE \(schemaTable) SET " + updatableFields.enumerated().map {
                $0.element.columnName + " = $\($0.offset+2)"
            }.joined(separator: ", ") + " WHERE \(primaryKeyField.columnName) = $1"
            preparedStatements.append(.init(name: "update", parameters: [primaryKeyField] + updatableFields, returnedColumns: [], sql: updateSQL))
            
            for field in updatableFields {
                if !field.behavior.contains(.dontCreatePreparedStatements) {
                    let sql = "UPDATE \(schemaTable) SET \(field.columnName) = $2 WHERE \(primaryKeyField.columnName) = $1"
                    preparedStatements.append(.init(name: "update\(field.formattedName)", parameters: [primaryKeyField, field], returnedColumns: [], sql: sql))
                }
            }

            let selectSQL = "SELECT \(allColumnsJoined) FROM \(schemaTable) WHERE \(primaryKeyField.columnName) = $1"
            preparedStatements.append(.init(name: "select", parameters: [primaryKeyField], returnedColumns: fields, sql: selectSQL))
        }
        
        let selectAllSQL = "SELECT \(allColumnsJoined) FROM \(schemaTable)"
        preparedStatements.append(.init(name: "selectAll", parameters: [], returnedColumns: fields, sql: selectAllSQL))

        let selectWithLimitAndOffsetSQL = "SELECT \(allColumnsJoined) FROM \(schemaTable) LIMIT $1 OFFSET $2"
        preparedStatements.append(.init(
            name: "selectAllWithLimitAndOffset",
            parameters: [
                .init(expr: ExprSyntax(StringLiteralExprSyntax(content: "limit")), columnName: "limit", variableName: "", postgresDataType: .integer, behavior: []),
                .init(expr: ExprSyntax(StringLiteralExprSyntax(content: "offset")), columnName: "offset", variableName: "", postgresDataType: .integer, behavior: [])
            ],
            returnedColumns: fields,
            sql: selectWithLimitAndOffsetSQL
        ))
        for field in fields {
            if !field.behavior.contains(.dontCreatePreparedStatements) {
                let sql = "SELECT \(allColumnsJoined) FROM \(schemaTable) WHERE \(field.columnName) = $1"
                let name = field.formattedName
                preparedStatements.append(.init(
                    name: "selectAllWhere\(name)Equals",
                    parameters: [
                        .init(expr: ExprSyntax(StringLiteralExprSyntax(content: "")), columnName: field.columnName, variableName: field.variableName, postgresDataType: field.postgresDataType, behavior: [.dontCreatePreparedStatements])
                    ],
                    returnedColumns: fields, sql: sql
                ))
            }
        }

        for (selectFields, condition) in selectFilters {
            let sql = "SELECT \(selectFields.joined(separator: ", ")) FROM \(schemaTable) WHERE " + condition.sql
            var selectFieldsAndDataTypes = [ModelRevision.Column.Compiled]()
            for field in selectFields {
                if let target = fields.first(where: { $0.columnName == field }) {
                    selectFieldsAndDataTypes.append(target)
                } else {
                    // TODO: show compiler diagnostic
                    continue
                }
            }
            preparedStatements.append(.init(name: "selectAllWhere_" + condition.name, parameters: [], returnedColumns: selectFieldsAndDataTypes, sql: sql))
        }

        var preparedStatementsString = "public enum PostgresPreparedStatements {"
        for statement in preparedStatements {
            preparedStatementsString += postgresPreparedStatement(statement: statement, schema: schema, schemaAlias: schemaAlias, table: table)
        }
        preparedStatementsString += "\n    }"
        return preparedStatementsString
    }
    private static func postgresPreparedStatement(
        statement: PreparedStatement,
        schema: String,
        schemaAlias: String?,
        table: String
    ) -> String {
        let name = schema + "_" + table + "_" + statement.name.lowercased()
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