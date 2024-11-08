//
//  DatabaseTransaction.swift
//
//
//  Created by Evan Anderson on 11/7/24.
//

import Foundation

public protocol DatabaseTransaction : Sendable {
    associatedtype IDValue : Codable & Hashable & Sendable
    
    var id : IDValue { get }
}