
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
                .creationTimestamp(),
                .deletionTimestamp(),
                .restorationTimestamp(),
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
    var restored:Date?

    var email:String
    var password:String

    var test2:Bool
}

extension UserAccount {
    static func postgresDecode(columns: [String?]) throws -> Self? {
        guard columns.count == 7 else { return nil }
        guard let id = IDValue(columns[0]!) else { return nil }
        let created:Date?
        if let v = columns[1] {
            created = try .postgresDecode(v, as: .timestampNoTimeZone(precision: 0))
        } else {
            created = nil
        }
        let deleted:Date?
        if let v = columns[2] {
            deleted = try .postgresDecode(v, as: .timestampNoTimeZone(precision: 0))
        } else {
            deleted = nil
        }
        let restored:Date?
        if let v = columns[3] {
            restored = try .postgresDecode(v, as: .timestampNoTimeZone(precision: 0))
        } else {
            restored = nil
        }
        let email = columns[4]!
        let password = columns[5]!
        let test2 = columns[6]!.first == "t"
        return .init(id: id, created: created, deleted: deleted, restored: restored, email: email, password: password, test2: test2)
    }
}