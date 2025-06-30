
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
    table: TestModels.users,
    selectFilters: [
        (["id"], .init(name: "passwordIsPASSWORD", firstCondition: .init(field: "password", operator: .equal, value: "PASSWORD")))
    ],
    revisions: [
        .init(
            addedFields: [
                .primaryKey(name: "id"),
                .optional(
                    .timestampNoTimeZone(
                        name: "created",
                        defaultValue: .sqlNow(),
                        autoCreatePreparedStatements: false
                    ),
                ),
                .optional(
                    .timestampNoTimeZone(
                        name: "deleted",
                        autoCreatePreparedStatements: false
                    )
                ),
                .string(name: "email"),
                .string(name: "password")
            ],
            removedFields: ["loop"]
        ),
        .init(
            addedFields: [
                .bool(
                    name: "test2",
                    defaultValue: false
                )
            ]
        )/*,
        .init(
            removedFields: ["test2"]
        )*/
    ]
)
struct UserAccount: PostgresModel {
    typealias IDValue = Int64

    var id:IDValue

    var created:Date?
    var deleted:Date?

    var email:String
    var password:String

    var test2:Bool
}

extension UserAccount {
    static func postgresDecode(columns: [String?]) throws -> Self? {
        guard columns.count == 6 else { return nil }
        guard let id = IDValue(columns[0]!) else { return nil }
        let created:Date?
        if let v = columns[1] {
            created = try Date.postgresDecode(v, as: .timestampNoTimeZone(precision: 0))
        } else {
            created = nil
        }
        let deleted:Date?
        if let v = columns[2] {
            deleted = try Date.postgresDecode(v, as: .timestampNoTimeZone(precision: 0))
        } else {
            deleted = nil
        }
        let email = columns[3]!
        let password = columns[4]!
        let test2 = columns[5]!.first == "t"
        return .init(id: id, created: created, deleted: deleted, email: email, password: password, test2: test2)
    }
}