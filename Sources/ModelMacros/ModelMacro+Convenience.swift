
import ModelUtilities
import SwiftDiagnostics
import SwiftSyntaxMacros

extension ModelMacro {
    static func convenienceLogic(
        context: some MacroExpansionContext,
        structureName: String,
        supportedDatabases: Set<DatabaseType>,
        schema: String,
        fields: [ModelRevision.Field.Compiled]
    ) -> String {
        var string = "extension \(structureName) {\n"
        if supportedDatabases.contains(.postgreSQL) {
            string += postgresCreateOnConnection(context: context, fields: fields)
        }
        string += "\n}"
        return string
    }
}

extension ModelMacro {
    private static func postgresCreateOnConnection(
        context: some MacroExpansionContext,
        fields: [ModelRevision.Field.Compiled]
    ) -> String {
        var validFieldNames = [String]()
        for field in fields {
            if field.postgresDataType != nil {
                validFieldNames.append(field.name)
            } else {
                context.diagnose(Diagnostic(node: field.expr, message: DiagnosticMsg.modelRevisionFieldMissingPostgresDataType()))
            }
        }
        let allValidFieldNames = validFieldNames
        let requireID:String
        let primaryKeyString:String
        if let primaryKeyFieldIndex = fields.firstIndex(where: { $0.constraints.contains(.primaryKey) }) {
            let primaryKeyField = fields[primaryKeyFieldIndex]
            requireID = "let \(primaryKeyField.name) = try requireID()\n"
            if primaryKeyField.postgresDataType == .serial || primaryKeyField.postgresDataType == .bigserial {
                primaryKeyString = ""
                validFieldNames.remove(at: primaryKeyFieldIndex)
            } else {
                primaryKeyString = requireID
            }
        } else {
            requireID = ""
            primaryKeyString = ""
        }

        let parametersJoined = validFieldNames.joined(separator: ", ")
        var string = "@discardableResult\n@inlinable\npublic func create<T: SQLQueryableProtocol & ~Copyable>(\n"
        string += "on queryable: borrowing T,\nexplain: Bool = false,\nanalyze: Bool = false\n) async throws -> Self {\n"
        string += primaryKeyString
        string += "let response = try await PostgresPreparedStatements.insert.execute(\non: queryable,\nparameters: (\(parametersJoined)),\nexplain: explain,\nanalyze: analyze\n)\n"
        string += "return self\n"
        string += "}\n\n"

        string += "@discardableResult\n@inlinable\npublic func update<T: SQLQueryableProtocol & ~Copyable>(\n"
        string += "on queryable: borrowing T,\nexplain: Bool = false,\nanalyze: Bool = false\n) async throws -> Self {\n"
        string += requireID
        string += "let response = try await PostgresPreparedStatements.update.execute(\non: queryable,\nparameters: (\(allValidFieldNames.joined(separator: ", "))),\nexplain: explain,\nanalyze: analyze\n)\n"
        string += "return self\n"
        string += "}"
        return string
    }
}