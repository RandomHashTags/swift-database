//
//  PostgresDatabase.swift
//
//
//  Created by Evan Anderson on 11/7/24.
//

import SQL
import SwiftDatabase

public protocol PostgresDatabase : SQLDatabase where Command == PostgresCommand {
}