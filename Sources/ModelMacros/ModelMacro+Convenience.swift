
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
        var string = "@inlinable public func create<T: PostgresConnectionProtocol & ~Copyable>(\n"
        string += "on connection: borrowing T,\nexplain: Bool = false,\nanalyze: Bool = false\n) async throws -> Self {\n"

        var validFieldNames = [String]()
        for field in fields {
            if let _ = field.postgresDataType {
                validFieldNames.append(field.name)
            } else {
                context.diagnose(Diagnostic(node: field.expr, message: DiagnosticMsg.modelRevisionFieldMissingPostgresDataType()))
            }
        }
        if let primaryKeyField = fields.first(where: { $0.constraints.contains(.primaryKey) }) {
            string += "let \(primaryKeyField.name) = try requireID()"
        }
        string += "let response = try await PostgresPreparedStatements.insert.execute(\non: connection,\nparameters: (\(validFieldNames.joined(separator: ", "))),\nexplain: explain,\nanalyze: analyze\n)\n"
        string += "return self"
        string += "\n}"
        return string
    }
}