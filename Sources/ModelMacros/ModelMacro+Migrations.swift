
import ModelUtilities
import SwiftDiagnostics
import SwiftSyntaxMacros

extension ModelMacro {
    static func migrations(
        context: some MacroExpansionContext,
        supportedDatabases: Set<DatabaseType>,
        schema: String,
        revisions: [ModelRevision.Compiled]
    ) -> String {
        var migrationsString = ""
        if !revisions.isEmpty {
            let sortedRevisions = revisions.sorted(by: { $0.version < $1.version })
            if supportedDatabases.contains(.postgreSQL) {
                migrationsString += "public enum PostgresMigrations {\n"
                migrationsString += postgresMigrations(context: context, schema: schema, revisions: sortedRevisions)
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
        revisions: [ModelRevision.Compiled]
    ) -> String {
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
        let createTableSQL = "CREATE TABLE IF NOT EXISTS " + schema + " (" + addedFieldsString + ");"
        migrations.append(("create", createTableSQL))

        for revision in revisions {
            let (name, sql) = postgresIncrementalMigration(context: context, schema: schema, revision: revision)
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
        revision: ModelRevision.Compiled
    ) -> (name: String, sql: String) {
        let version = revision.version
        let incrementalName = "incremental_\("v\(version.0)_\(version.1)_\(version.2)")"
        var incrementalSQL = ""
        for field in revision.addedFields {
            if let dataType = field.postgresDataType {
                var sql = "ALTER TABLE \(schema) ADD COLUMN \(field.name) \(dataType.name)"
                if !field.constraints.isEmpty {
                    if field.defaultValue == nil && field.constraints.contains(.notNull) {
                        context.diagnose(Diagnostic(node: field.expr, message: DiagnosticMsg.notNullFieldMissingDefaultValue()))
                        continue
                    }
                    sql += " " + field.constraints.map({ $0.name }).joined(separator: ", ")
                }
                if let defaultValue = field.defaultValue {
                    sql += " DEFAULT " + defaultValue
                }
                incrementalSQL += sql + ";"
            } else {
                context.diagnose(Diagnostic(node: field.expr, message: DiagnosticMsg.modelRevisionFieldMissingPostgresDataType()))
                continue
            }
        }
        return (incrementalName, incrementalSQL)
    }
}