
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

extension UserAccount {
    static func postgresDecode(columns: [ByteBuffer?]) throws -> Self? {
        guard columns.count == 8 else { return nil }
        guard let id = IDValue(columns[0]!.utf8String()) else { return nil }
        let created:Date?
        if let v = columns[1]?.utf8String() {
            created = try .postgresDecode(v, as: .timestampNoTimeZone(precision: 0))
        } else {
            created = nil
        }
        let deleted:Date?
        if let v = columns[2]?.utf8String() {
            deleted = try .postgresDecode(v, as: .timestampNoTimeZone(precision: 0))
        } else {
            deleted = nil
        }
        let restored:Date?
        if let v = columns[3]?.utf8String() {
            restored = try .postgresDecode(v, as: .timestampNoTimeZone(precision: 0))
        } else {
            restored = nil
        }
        let email = columns[4]!.utf8String()
        let password = columns[5]!.utf8String()
        let c:UInt8
        if let column = columns[6] {
            let dehexed = column.postgresBYTEAHexadecimal()
            c = UInt8(dehexed) ?? 0
        } else {
            c = 0
        }
        let country = PostgresUInt8DataType(integerLiteral: c)
        let test2 = columns[7]!.utf8String().first == "t"
        return .init(id: id, created: created, deleted: deleted, restored: restored, email: email, password: password, country: country, test2: test2)
    }
}