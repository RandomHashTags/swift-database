
import SwiftSyntax
import SwiftSyntaxMacros

enum ModelMacro: DeclarationMacro {
    static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        var schema = ""
        var parameters = [(name: String, dataType: String)]()

        var preparedStatements = [String]()
        return []
    }
}