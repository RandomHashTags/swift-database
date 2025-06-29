
#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

import Models
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

@Model(
    supportedDatabases: [.postgreSQL],
    schema: "public",
    table: "user_posts",
    revisions: [
        .init(
            addedFields: [
                .init(
                    name: "id",
                    constraints: [.primaryKey],
                    postgresDataType: .bigserial
                ),
                .optional(
                    .timestampNoTimeZone(
                        name: "created",
                        defaultValue: .sqlNow()
                    ),
                ),
                .optional(
                    .timestampNoTimeZone(
                        name: "deleted"
                    )
                ),
                .init(
                    name: "user_id",
                    variableName: "userID",
                    constraints: [.notNull, .references(schema: "public", table: "users", fieldName: "id")],
                    postgresDataType: .bigserial
                ),
                .string(
                    name: "content"
                )
            ]
        ),
        .init(
            newTableName: "user_comments",
            updatedFields: [
                .string(
                    name: "content" // TODO: show compiler diagnostic about being unable to update field due to the field already being of same data type
                )
            ]
        ),
        .init(
            renamedFields: [
                ("content", "text")
            ]
        )
    ]
)
struct UserComment: PostgresModel {
    typealias IDValue = Int64

    var id:IDValue

    var created:Date?
    var deleted:Date?

    var userID:UserAccount.IDValue

    var text:String
}

extension UserComment {
    static func postgresDecode(columns: [String?]) throws -> Self? {
        return nil
    }
}