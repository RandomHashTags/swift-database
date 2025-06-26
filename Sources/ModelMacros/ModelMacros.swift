
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

@main
struct ModelMacros: CompilerPlugin {
    let providingMacros:[any Macro.Type] = [ModelMacro.self]
}

extension ExprSyntax {
    package var array: ArrayExprSyntax? { self.as(ArrayExprSyntax.self) }
    package var declReference: DeclReferenceExprSyntax? { self.as(DeclReferenceExprSyntax.self) }
    package var dictionary: DictionaryExprSyntax? { self.as(DictionaryExprSyntax.self) }
    package var functionCall: FunctionCallExprSyntax? { self.as(FunctionCallExprSyntax.self) }
    package var integerLiteral: IntegerLiteralExprSyntax? { self.as(IntegerLiteralExprSyntax.self) }
    package var memberAccess: MemberAccessExprSyntax? { self.as(MemberAccessExprSyntax.self) }
    package var stringLiteral: StringLiteralExprSyntax? { self.as(StringLiteralExprSyntax.self) }
    package var tuple: TupleExprSyntax? { self.as(TupleExprSyntax.self) }

    package func integer<T: FixedWidthInteger>() -> T? { integerLiteral?.integer() }
}

extension IntegerLiteralExprSyntax {
    package func integer<T: FixedWidthInteger>() -> T? { T(literal.text) }
}

extension ExprSyntax {
    package func legalStringliteralText(context: some MacroExpansionContext, _ isLegal: (Character) -> Bool = { _ in false }) -> String? {
        guard let stringLiteral = stringLiteral else {
            context.diagnose(DiagnosticMsg.expectedStringLiteral(expr: self))
            return nil
        }
        return stringLiteral.legalText(context: context, isLegal)
    }
}

extension StringLiteralExprSyntax {
    package var text: String { segments.description }
    package func legalText(context: some MacroExpansionContext, _ isLegal: (Character) -> Bool = { _ in false }) -> String? {
        if let illegal = text.first(where: { !($0.isLetter || $0.isNumber || $0 == "_" || isLegal($0)) }) {
            context.diagnose(DiagnosticMsg.stringLiteralContainsIllegalCharacter(expr: self, char: illegal))
            return nil
        }
        return text
    }
}