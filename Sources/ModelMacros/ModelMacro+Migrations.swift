
import ModelUtilities
import SwiftDiagnostics
import SwiftSyntaxMacros

extension ModelMacro {
    static func migrations(
        context: some MacroExpansionContext,
        supportedDatabases: Set<DatabaseType>,
        schema: String,
        schemaAlias: String?,
        table: String,
        revisions: [ModelRevision.Compiled]
    ) -> String {
        var migrationsString = ""
        if !revisions.isEmpty {
            if supportedDatabases.contains(.postgreSQL) {
                migrationsString += "public enum PostgresMigrations {\n"
                migrationsString += postgresMigrations(context: context, schema: schema, schemaAlias: schemaAlias, table: table, revisions: revisions)
                migrationsString += "\n    }"
            }
        }
        return migrationsString
    }
}

// MARK: Postgres
extension ModelMacro {
    private static func postgresMigrations(
        context: some MacroExpansionContext,
        schema: String,
        schemaAlias: String?,
        table: String,
        revisions: [ModelRevision.Compiled]
    ) -> String {
        let schemaTable = schema + "." + table
        var migrations = [(name: String, sql: String)]()
        var revisions = revisions
        let initialRevision = revisions.removeFirst()

        let addedFieldsString:String = initialRevision.addedFields.compactMap({
            guard let dataType = $0.postgresDataType?.name else {
                context.diagnose(Diagnostic(node: $0.expr, message: DiagnosticMsg.modelRevisionFieldMissingPostgresDataType()))
                return nil
            }
            let constraintsString = $0.constraints.map({ $0.name }).joined(separator: " ")
            return $0.name + " " + dataType + (constraintsString.isEmpty ? "" : " " + constraintsString)
        }).joined(separator: ", ")

        if schema != "public" {
            let createSchemaSQL = "CREATE SCHEMA IF NOT EXISTS " + schema
            migrations.append(("createSchema", createSchemaSQL))
        }

        let createTableSQL = "CREATE TABLE IF NOT EXISTS " + schemaTable + " (" + addedFieldsString + ");"
        migrations.append(("createTable", createTableSQL))

        for revision in revisions {
            let (name, sql) = postgresIncrementalMigration(context: context, schema: schema, schemaAlias: schemaAlias, table: table, revision: revision)
            if !sql.isEmpty {
                migrations.append((name, sql))
            } else {
                // TODO: show compiler diagnostic
            }
        }

        return migrations.map({ (name, sql) in
            return "        @inlinable public static var " + name + ": String { \"" + sql + "\" }"
        }).joined(separator: "\n")
    }
    private static func postgresIncrementalMigration(
        context: some MacroExpansionContext,
        schema: String,
        schemaAlias: String?,
        table: String,
        revision: ModelRevision.Compiled
    ) -> (name: String, sql: String) {
        let schemaTable = schema + "." + table
        let version = revision.version
        let incrementalName = "incremental_v\(version.0)_\(version.1)_\(version.2)"
        var incrementalSQL = ""

        if !revision.addedFields.isEmpty {
            incrementalSQL += revision.addedFields.compactMap({ field in
                guard let dataType = field.postgresDataType else {
                    context.diagnose(Diagnostic(node: field.expr, message: DiagnosticMsg.modelRevisionFieldMissingPostgresDataType()))
                    return nil
                }
                var sql = "ADD COLUMN \(field.name) \(dataType.name)"
                if !field.constraints.isEmpty {
                    if field.defaultValue == nil && field.constraints.contains(.notNull) {
                        context.diagnose(Diagnostic(node: field.expr, message: DiagnosticMsg.notNullFieldMissingDefaultValue()))
                        return nil
                    }
                    sql += " " + field.constraints.map({ $0.name }).joined(separator: ", ")
                }
                if let defaultValue = field.defaultValue {
                    sql += " DEFAULT " + defaultValue
                }
                return sql
            }).joined(separator: ", ")
        }
        if !revision.updatedFields.isEmpty {
            if !incrementalSQL.isEmpty {
                incrementalSQL += ", "
            }
            incrementalSQL += revision.updatedFields.compactMap({
                guard let dt = $0.postgresDataType else { return nil }
                return "SET DATA TYPE \(dt.name)"
            }).joined(separator: ", ")
        }
        if !revision.renamedFields.isEmpty {
            if !incrementalSQL.isEmpty {
                incrementalSQL += ", "
            }
            incrementalSQL += revision.renamedFields.map({
                "RENAME COLUMN \($0.from) TO \($0.to)"
            }).joined(separator: ", ")
        }
        if !revision.removedFields.isEmpty {
            if !incrementalSQL.isEmpty {
                incrementalSQL += ", "
            }
            incrementalSQL += revision.removedFields.map({
                "DROP COLUMN \($0.name)"
            }).joined(separator: ", ")
        }
        if !incrementalSQL.isEmpty {
            incrementalSQL = "ALTER TABLE \(schemaTable) " + incrementalSQL + ";"
        }
        return (incrementalName, incrementalSQL)
    }
}