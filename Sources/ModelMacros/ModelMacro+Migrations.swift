
import ModelUtilities

extension ModelMacro {
    static func migrations(
        supportedDatabases: Set<DatabaseType>,
        schema: String,
        revisions: [ModelRevision]
    ) -> String {
        var migrationsString = ""
        if !revisions.isEmpty {
            let sortedRevisions = revisions.sorted(by: { $0.version < $1.version })
            if supportedDatabases.contains(.postgreSQL) {
                migrationsString += "public enum PostgresMigrations {\n"
                migrationsString += postgresMigrations(schema: schema, revisions: sortedRevisions)
                migrationsString += "\n    }"
            }
        }
        return migrationsString
    }
}

// MARK: Postgres
extension ModelMacro {
    private static func postgresMigrations(schema: String, revisions: [ModelRevision]) -> String {
        var migrations = [(name: String, sql: String)]()
        var revisions = revisions
        let initialRevision = revisions.removeFirst()
        let addedFieldsString:String = initialRevision.addedFields.compactMap({
            guard let dataType = $0.postgresDataType?.name else {
                // TODO: show compiler diagnostic
                return nil
            }
            let constraintsString = $0.constraints.map({ $0.name }).joined(separator: " ")
            return $0.name + " " + dataType + (constraintsString.isEmpty ? "" : " " + constraintsString)
        }).joined(separator: ", ")
        let createTableSQL = "CREATE TABLE IF NOT EXISTS " + schema + " (" + addedFieldsString + ");"
        migrations.append(("create", createTableSQL))

        for revision in revisions {
            let (name, sql) = postgresIncrementalMigration(schema: schema, revision: revision)
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
        schema: String,
        revision: ModelRevision
    ) -> (name: String, sql: String) {
        let incrementalName = "incremental_\("v\(revision.version.0)_\(revision.version.1)_\(revision.version.2)")"
        var incrementalSQL = ""
        for field in revision.addedFields {
            if let dataType = field.postgresDataType {
                var sql = "ALTER TABLE \(schema) ADD COLUMN \(field.name) \(dataType.name)"
                if !field.constraints.isEmpty {
                    if field.defaultValue == nil && field.constraints.contains(.notNull) {
                        // TODO: show compiler diagnostic
                        continue
                    }
                    sql += " " + field.constraints.map({ $0.name }).joined(separator: ", ")
                }
                if let defaultValue = field.defaultValue {
                    sql += " DEFAULT " + defaultValue
                }
                incrementalSQL += sql + ";"
            } else {
                // TODO: show compiler diagnostic
                continue
            }
        }
        return (incrementalName, incrementalSQL)
    }
}