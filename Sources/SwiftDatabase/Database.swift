//
//  Database.swift
//
//
//  Created by Evan Anderson on 11/7/24.
//

public protocol Database : Sendable {
    associatedtype Command : DatabaseCommand

    /// The address of the database we want to connect to.
    var address : String { get }
    /// The username of the user that controls the database we want to access.
    var username : String { get }
    /// The password to the database we want to access.
    var password : String? { get }

    /// How this database is stored.
    var storageMethod : DatabaseStorageMethod { get }

    /// Setup a connection to the database.
    func connect() async throws

    /// Close the connection to the database.
    func disconnect() throws

    /// Executes a command on the database.
    func execute(_ command: Command) async throws
}