
import ModelUtilities
import SwiftDiagnostics
import SwiftSyntaxMacros

extension ModelMacro {
    static func convenienceLogic(
        context: some MacroExpansionContext,
        construct: ModelConstruct,
        supportedDatabases: Set<DatabaseType>,
        schema: String,
        fields: [ModelRevision.Column.Compiled]
    ) -> String {
        var string = ""
        if supportedDatabases.contains(.postgreSQL) {
            string += postgresCreateOnConnection(context: context, construct: construct, fields: fields)
        }
        if !string.isEmpty {
            string = "extension " + construct.name + " {\n" + string + "\n}"
        }
        return string
    }
}

// MARK: Postgres
extension ModelMacro {
    private static func postgresCreateOnConnection(
        context: some MacroExpansionContext,
        construct: ModelConstruct,
        fields: [ModelRevision.Column.Compiled]
    ) -> String {
        for field in fields {
            if field.postgresDataType == nil {
                context.diagnose(Diagnostic(node: field.expr, message: DiagnosticMsg.modelRevisionFieldMissingPostgresDataType()))
            }
        }
        let primaryKeyColumnName:String?
        let requireID:String
        let primaryKeyString:String
        if let primaryKeyField = fields.primaryKey {
            primaryKeyColumnName = primaryKeyField.columnName
            requireID = "let \(primaryKeyField.columnName) = try requireID()\n"
            if primaryKeyField.postgresDataType == .serial || primaryKeyField.postgresDataType == .bigserial {
                primaryKeyString = ""
            } else {
                primaryKeyString = requireID
            }
        } else {
            primaryKeyColumnName = nil
            requireID = ""
            primaryKeyString = ""
        }

        let insertableFieldsJoined = fields.insertableFields.map { $0.variableName }.joined(separator: ", ")
        var updatableFieldsJoined:String = fields.updatableFields.map { $0.variableName }.joined(separator: ", ")
        if let pk = fields.primaryKey {
            updatableFieldsJoined = pk.variableName + ", " + updatableFieldsJoined
        }
        let mutationKeyword = construct.isStruct ? "mutating " : ""
        var string = "@discardableResult\n@inlinable\npublic \(mutationKeyword)func create<T: PostgresQueryableProtocol & ~Copyable>(\n"
        string += "on queryable: inout T,\nexplain: Bool = false,\nanalyze: Bool = false\n) async throws -> Self {\n"
        string += primaryKeyString
        string += "let response = try await PostgresPreparedStatements.insertReturning.execute(\non: &queryable,\nparameters: (\(insertableFieldsJoined)),\nexplain: explain,\nanalyze: analyze\n).requireNotError()\n"
        string += """
        if let msg = response.asRowDescription(),
                let decoded = try await msg.decode(on: &queryable, as: Self.self).first,
                let decoded {
            \(construct.isStruct ? "self =" : "return") decoded
        }
        """
        string += "return self\n"
        string += "}\n\n"

        string += """
        @discardableResult
        @inlinable
        public \(mutationKeyword)func update<T: PostgresQueryableProtocol & ~Copyable>(
            on queryable: inout T,
            explain: Bool = false,
            analyze: Bool = false
        ) async throws -> Self {
            \(requireID)let response = try await PostgresPreparedStatements.update.execute(
                on: &queryable,
                parameters: (\(updatableFieldsJoined)),
                explain: explain,
                analyze: analyze
            ).requireNotError()
            return self
        }
        """

        if let primaryKeyColumnName, let softDeletionField = fields.softDeletionField {
            string += """
            @discardableResult
            @inlinable
            public \(mutationKeyword)func softDelete<T: PostgresQueryableProtocol & ~Copyable>(
                on queryable: inout T,
                explain: Bool = false,
                analyze: Bool = false
            ) async throws -> Self {
                \(requireID)let response = try await PostgresPreparedStatements.softDelete.execute(
                    on: &queryable,
                    parameters: (\(primaryKeyColumnName)),
                    explain: explain,
                    analyze: analyze
                ).requireNotError()
                return self
            }
            """

            if let restorationField = fields.restorationField {
                string += """
                @discardableResult
                @inlinable
                public \(mutationKeyword)func restore<T: PostgresQueryableProtocol & ~Copyable>(
                    on queryable: inout T,
                    explain: Bool = false,
                    analyze: Bool = false
                ) async throws -> Self {
                    \(requireID)let response = try await PostgresPreparedStatements.restore.execute(
                        on: &queryable,
                        parameters: (\(primaryKeyColumnName)),
                        explain: explain,
                        analyze: analyze
                    ).requireNotError()
                    return self
                }
                """
            }
        }
        return string
    }
}