
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
        var string = "@discardableResult\n@inlinable\npublic func create<T: PostgresConnectionProtocol & ~Copyable>(\n"
        string += "on connection: borrowing T,\nexplain: Bool = false,\nanalyze: Bool = false\n) async throws -> Self {\n"

        var validFieldNames = [String]()
        for field in fields {
            if let _ = field.postgresDataType {
                validFieldNames.append(field.name)
            } else {
                context.diagnose(Diagnostic(node: field.expr, message: DiagnosticMsg.modelRevisionFieldMissingPostgresDataType()))
            }
        }
        let primaryKeyString:String
        if let primaryKeyFieldIndex = fields.firstIndex(where: { $0.constraints.contains(.primaryKey) }) {
            let primaryKeyField = fields[primaryKeyFieldIndex]
            if primaryKeyField.postgresDataType == .serial || primaryKeyField.postgresDataType == .bigserial {
                primaryKeyString = ""
                validFieldNames.remove(at: primaryKeyFieldIndex)
            } else {
                primaryKeyString = "let \(primaryKeyField.name) = try requireID()\n"
            }
        } else {
            primaryKeyString = ""
        }

        let parametersJoined = validFieldNames.joined(separator: ", ")
        string += primaryKeyString
        string += "let response = try await PostgresPreparedStatements.insert.execute(\non: connection,\nparameters: (\(parametersJoined)),\nexplain: explain,\nanalyze: analyze\n)\n"
        string += "return self\n"
        string += "}\n\n"

        string += "@discardableResult\n@inlinable\npublic func create<T: PostgresTransactionProtocol & ~Copyable>(\n"
        string += "on transaction: borrowing T,\nexplain: Bool = false,\nanalyze: Bool = false\n) async throws -> Self {\n"
        string += primaryKeyString
        string += "let response = try await PostgresPreparedStatements.insert.execute(\non: transaction,\nparameters: (\(parametersJoined)),\nexplain: explain,\nanalyze: analyze\n)\n"
        string += "return self\n"
        string += "\n}"
        return string
    }
}