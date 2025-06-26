
#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

import Model
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

@Model(
    supportedDatabases: [.postgreSQL],
    schema: "public",
    table: "user_comments",
    revisions: [
        .init(
            version: (0, 0, 1),
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
                    name: "content",
                    postgresDataType: .characterVarying(count: 255)
                )
            ]
        ),
        .init(
            version: (0, 0, 2),
            updatedFields: [
                .init(
                    name: "content",
                    postgresDataType: .text
                )
            ]
        ),
        .init(
            version: (0, 0, 3),
            renamedFields: [
                ("content", "text")
            ]
        )
    ]
)
struct UserComment: Model {
    typealias IDValue = Int64

    var id:IDValue

    var created:Date
    var deleted:Date?

    var text:String
}

extension UserComment: PostgresDataRowDecodable {
    static func postgresDecode(columns: [String?]) throws -> Self? {
        return nil
    }
}