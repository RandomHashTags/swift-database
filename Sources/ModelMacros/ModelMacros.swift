
import SwiftCompilerPlugin
import SwiftSyntaxMacros
import SwiftDiagnostics

@main
struct ModelMacros: CompilerPlugin {
    let providingMacros:[any Macro.Type] = []
}