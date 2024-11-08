//
//  TransactionableDatabase.swift
//
//
//  Created by Evan Anderson on 11/7/24.
//

public protocol TransactionableDatabase : Database {
    associatedtype Transaction : DatabaseTransaction

    @discardableResult
    func transaction<V>(_ work: (borrowing Transaction) async throws -> V) async rethrows -> V
}