//
//  DatabaseCommand.swift
//
//
//  Created by Evan Anderson on 11/7/24.
//

public protocol DatabaseCommand : Sendable, ExpressibleByStringLiteral where StringLiteralType == String {
}