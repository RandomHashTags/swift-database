
#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

import Models
import ModelUtilities
import PostgreSQLBlueprint
import SwiftDatabaseBlueprint

@Model(
    supportedDatabases: [.postgreSQL],
    schema: TestSchemas.public,
    table: TestModels.users,
    /*partition: .init(
        form: .list(by: "0"),
        column: "country"
    ),*/
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
                .string(name: "password"),
                .uint8(
                    name: "country",
                    behavior: [.dontCreatePreparedStatements]
                )
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

    var country:PostgresUInt8DataType
    var test2:Bool
}