
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
        var values = [String]()
        if supportedDatabases.contains(.postgreSQL) {
            values.append(contentsOf: postgresConvenienceLogic(context: context, construct: construct, fields: fields))
        }
        var string = ""
        if !values.isEmpty {
            string += "extension " + construct.name + " {\n" + values.joined(separator: "\n\n") + "\n}\n"
        }
        
        return string
    }
}

// MARK: Postgres
extension ModelMacro {
    private static func postgresConvenienceLogic(
        context: some MacroExpansionContext,
        construct: ModelConstruct,
        fields: [ModelRevision.Column.Compiled]
    ) -> [String] {
        var valid = true
        for field in fields {
            if field.postgresDataType == nil {
                context.diagnose(Diagnostic(node: field.expr, message: DiagnosticMsg.modelRevisionFieldMissingPostgresDataType()))
                valid = false
            }
        }
        guard valid else { return [] }
        return [
            "// MARK: Postgres CRUD\n" + postgresCRUD(context: context, construct: construct, fields: fields),
            "// MARK: Postgres Decode\n" + postgresDecode(context: context, fields: fields)
        ]
    }
    private static func postgresCRUD(
        context: some MacroExpansionContext,
        construct: ModelConstruct,
        fields: [ModelRevision.Column.Compiled]
    ) -> String {
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
    private static func postgresDecode(
        context: some MacroExpansionContext,
        fields: [ModelRevision.Column.Compiled]
    ) -> String {
        var initializer = [String]()
        var string = "@inlinable\npublic static func postgresDecode(columns: [ByteBuffer?]) throws -> Self? {\n"
        string += "guard columns.count == \(fields.count) else { return nil }\n"
        var primaryKeyIndex:Int? = nil
        if let pki = fields.firstIndex(where: { $0.constraints.contains(.primaryKey) }) {
            primaryKeyIndex = pki
            let pkiVariableName = fields[pki].variableName
            string += "guard let \(pkiVariableName) = IDValue(columns[\(pki)]!.utf8String()) else { return nil }\n"
            initializer.append(pkiVariableName)
        }
        for (index, field) in fields.enumerated() {
            if index != primaryKeyIndex {
                if let decoded = postgresDecoded(context: context, index: index, field: field) {
                    string += decoded
                    initializer.append(field.variableName)
                }
            }
        }
        string += "return .init(\n" + initializer.map({ "\($0): \($0)" }).joined(separator: ",\n") + "\n)"
        return string + "\n}\n"
    }
    private static func postgresDecoded(
        context: some MacroExpansionContext,
        index: Int,
        field: ModelRevision.Column.Compiled
    ) -> String? {
        let dataType = field.postgresDataType!
        let normalizedPostgresSwiftDataType = field.normalizedPostgresSwiftDataType!
        let variableName = field.variableName
        let isRequired = field.isRequired
        let wrapSymbol = isRequired ? "!" : "?"
        var decoded = "let \(variableName) = columns[\(index)]\(wrapSymbol).utf8String()"
        switch normalizedPostgresSwiftDataType {
        case "Bool":
            decoded += ".first == \"t\""
        case "Date",
                "Int16",
                "Int32",
                "Int64":
            decoded = postgresIfLetVColumn(isRequired: isRequired, dataType: dataType, index: index, variableName: variableName, typeAnnotation: normalizedPostgresSwiftDataType)
        case "String":
            break
        case "PostgresUInt8DataType":
            decoded = """
            let \(variableName):PostgresUInt8DataType
            let \(variableName)Dehexed = columns[\(index)]\(wrapSymbol).postgresBYTEAHexadecimal()
            if let v = UInt8(\(variableName)Dehexed) {
                \(variableName) = PostgresUInt8DataType(integerLiteral: v)
            } else {
                \(variableName) = 0
            }
            """
        default:
            context.diagnose(DiagnosticMsg.somethingWentWrong(expr: field.expr, message: "field.normalizedPostgresSwiftDataType=\(field.normalizedPostgresSwiftDataType)"))
            return nil
        }
        return decoded + "\n"
    }
    private static func postgresIfLetVColumn(
        isRequired: Bool,
        dataType: PostgresDataType,
        index: Int,
        variableName: String,
        typeAnnotation: String
    ) -> String {
        var decoded:String
        if isRequired {
            decoded = "guard let \(variableName) = try \(typeAnnotation).postgresDecode(columns[\(index)]!.utf8String(), as: .\(dataType)) else { return nil }\n"
        } else {
            decoded = """
            let \(variableName):\(typeAnnotation)?
            if let v = columns[\(index)]?.utf8String() {
                \(variableName) = try \(typeAnnotation).postgresDecode(v, as: .\(dataType))
            } else {
                \(variableName) = nil
            }
            """
        }
        return decoded
    }
}