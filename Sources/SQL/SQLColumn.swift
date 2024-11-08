//
//  SQLColumn.swift
//
//
//  Created by Evan Anderson on 11/7/24.
//

public protocol SQLColumn : Sendable {
    var name : String { get }
}