//
//  Migratable.swift
//
//
//  Created by Evan Anderson on 11/7/24.
//

import SwiftDatabaseUtilities

public protocol Migratable : Sendable {
    associatedtype DBVersion : DatabaseVersion
    associatedtype DBCommand : DatabaseCommand

    static var schema : String { get }
    static var migrations : [DBVersion : [DBCommand]] { get }
}