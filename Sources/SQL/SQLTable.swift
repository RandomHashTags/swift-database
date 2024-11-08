//
//  SQLTable.swift
//
//
//  Created by Evan Anderson on 11/7/24.
//

public protocol SQLTable : Sendable {
    associatedtype Record : SQLRecord

    static var schema : String { get }
}