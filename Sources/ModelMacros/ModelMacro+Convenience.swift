
import ModelUtilities
import SwiftDiagnostics
import SwiftSyntaxMacros

extension ModelMacro {
    static func convenienceLogic(
        context: some MacroExpansionContext,
        construct: ModelConstruct,
        supportedDatabases: Set<DatabaseType>,
        schema: String,
        fields: [ModelRevision.Field.Compiled]
    ) -> String {
        var string = "extension \(construct.name) {\n"
        if supportedDatabases.contains(.postgreSQL) {
            string += postgresCreateOnConnection(context: context, construct: construct, fields: fields)
        }
        string += "\n}"
        return string
    }
}

extension ModelMacro {
    private static func postgresCreateOnConnection(
        context: some MacroExpansionContext,
        construct: ModelConstruct,
        fields: [ModelRevision.Field.Compiled]
    ) -> String {
        var validFieldNames = [String]()
        for field in fields {
            if field.postgresDataType != nil {
                validFieldNames.append(field.variableName)
            } else {
                context.diagnose(Diagnostic(node: field.expr, message: DiagnosticMsg.modelRevisionFieldMissingPostgresDataType()))
            }
        }
        let allValidFieldNames = validFieldNames
        let requireID:String
        let primaryKeyString:String
        if let primaryKeyFieldIndex = fields.firstIndex(where: { $0.constraints.contains(.primaryKey) }) {
            let primaryKeyField = fields[primaryKeyFieldIndex]
            requireID = "let \(primaryKeyField.columnName) = try requireID()\n"
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
        let mutationKeyword = construct.isStruct ? "mutating " : ""
        var string = "@discardableResult\n@inlinable\npublic \(mutationKeyword)func create<T: PostgresQueryableProtocol & ~Copyable>(\n"
        string += "on queryable: inout T,\nexplain: Bool = false,\nanalyze: Bool = false\n) async throws -> Self {\n"
        string += primaryKeyString
        string += "let response = try await PostgresPreparedStatements.insertReturning.execute(\non: &queryable,\nparameters: (\(parametersJoined)),\nexplain: explain,\nanalyze: analyze\n).requireNotError()\n"
        string += """
        if let msg = response.asRowDescription(),
                let decoded = try await msg.decode(on: &queryable, as: Self.self).first,
                let decoded {
            \(construct.isStruct ? "self =" : "return") decoded
        }
        """
        string += "return self\n"
        string += "}\n\n"

        string += "@discardableResult\n@inlinable\npublic \(mutationKeyword)func update<T: PostgresQueryableProtocol & ~Copyable>(\n"
        string += "on queryable: inout T,\nexplain: Bool = false,\nanalyze: Bool = false\n) async throws -> Self {\n"
        string += requireID
        string += "let response = try await PostgresPreparedStatements.update.execute(\non: &queryable,\nparameters: (\(allValidFieldNames.joined(separator: ", "))),\nexplain: explain,\nanalyze: analyze\n).requireNotError()\n"
        string += "return self\n"
        string += "}"
        return string
    }
}