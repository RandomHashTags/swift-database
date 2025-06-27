
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
                .init(
                    name: "created",
                    postgresDataType: .timestampNoTimeZone(precision: 0)
                ),
                .init(
                    name: "deleted",
                    constraints: [],
                    postgresDataType: .timestampNoTimeZone(precision: 0)
                ),
                .init(
                    name: "user_id",
                    variableName: "userID",
                    constraints: [.notNull, .references(schema: "public", table: "users", fieldName: "id")],
                    postgresDataType: .bigserial
                ),
                .init(
                    name: "content",
                    postgresDataType: .characterVarying(count: 255)
                )
            ]
        ),
        .init(
            newTableName: "user_comments",
            updatedFields: [
                .init(
                    name: "content",
                    postgresDataType: .text
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

    var created:Date
    var deleted:Date?

    var userID:UserAccount.IDValue

    var text:String
}

extension UserComment {
    static func postgresDecode(columns: [String?]) throws -> Self? {
        return nil
    }
}