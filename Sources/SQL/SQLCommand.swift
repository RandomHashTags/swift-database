//
//  SQLCommand.swift
//
//
//  Created by Evan Anderson on 11/7/24.
//

import SwiftDatabase

public protocol SQLCommand : DatabaseCommand {
    var sqlValue : String { get }
}