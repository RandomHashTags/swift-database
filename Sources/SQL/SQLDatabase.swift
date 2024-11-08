//
//  SQLDatabase.swift
//
//
//  Created by Evan Anderson on 11/7/24.
//

import SwiftDatabase

public protocol SQLDatabase : RelationalDatabase, TransactionableDatabase {
    associatedtype Table : SQLTable
}