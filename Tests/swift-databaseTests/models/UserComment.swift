
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
    schema: TestSchemas.public,
    table: TestModels.user_posts,
    revisions: [
        .init(
            addedFields: [
                .primaryKey(name: "id"),
                .creationTimestamp(),
                .deletionTimestamp(),
                .restorationTimestamp(),
                .optional(
                    .timestampNoTimeZone(
                        name: "last_updated",
                        variableName: "lastUpdated",
                        behavior: [
                            .dontCreatePreparedStatements,
                            .notInsertable,
                            .notUpdatable
                        ]
                    )
                ),
                .primaryKeyReference(
                    referencing: (schema: TestSchemas.public, table: TestModels.users, fieldName: \UserAccount.id),
                    name: "user_id",
                    variableName: "userID",
                    behavior: [
                        .notUpdatable
                    ]
                ),
                .string(name: "content")
            ]
        ),
        .init(
            newTableName: TestModels.user_comments,
            updatedFields: [
                .string(name: "content")
            ],
            renamedFields: [
                ("dood", "dude")
            ],
            removedFields: [
                "lol"
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
    var restored:Date?
    var lastUpdated:Date?

    var userID:UserAccount.IDValue

    var text:String
}