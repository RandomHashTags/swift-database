//
//  SwiftDatabaseMacros.swift
//
//
//  Created by Evan Anderson on 11/7/24.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros
import SwiftDiagnostics

@main
struct SwiftDatabaseMacros : CompilerPlugin {
    let providingMacros:[any Macro.Type] = []
}
