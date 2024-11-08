//
//  Migration.swift
//
//
//  Created by Evan Anderson on 11/7/24.
//

public protocol Migration : Sendable {
    associatedtype DBVersion : DatabaseVersion

    static var schema : String { get }

    var id : DBVersion { get }
    var name : String? { get }

    func migrate(on database: any Database, asTransaction: Bool) async throws
    func revert(on database: any Database, asTransaction: Bool) async throws
}