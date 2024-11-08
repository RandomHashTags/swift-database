//
//  SQLRecord.swift
//
//
//  Created by Evan Anderson on 11/7/24.
//

import SwiftDatabase

public protocol SQLRecord : Migratable {
    associatedtype IDValue : Codable & Hashable & Sendable
    associatedtype Attribute : SQLAttribute

    var id : IDValue { get }
}