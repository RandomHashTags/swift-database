
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
    package func legalStringLiteralText(context: some MacroExpansionContext, _ isLegal: (Character) -> Bool = { _ in false }) -> String? {
        guard let stringLiteral = stringLiteral else {
            context.diagnose(DiagnosticMsg.expectedStringLiteral(expr: self))
            return nil
        }
        return stringLiteral.legalText(context: context, isLegal)
    }
    package func legalStringLiteralOrMemberAccessText(context: some MacroExpansionContext, _ isLegal: (Character) -> Bool = { _ in false }) -> String? {
        if let stringLiteral {
            return stringLiteral.legalText(context: context, isLegal)
        }
        if let memberAccess {
            return memberAccess.declName.baseName.text.legalText(context: context, expr: memberAccess.declName)
        }
        context.diagnose(DiagnosticMsg.expectedStringLiteralOrMemberAccess(expr: self))
        return nil
    }
}

extension StringLiteralExprSyntax {
    package var text: String { segments.description }
    package func legalText(context: some MacroExpansionContext, _ isLegal: (Character) -> Bool = { _ in false }) -> String? {
        return text.legalText(context: context, expr: self, isLegal)
    }
}
extension String {
    package func legalText(context: some MacroExpansionContext, expr: some ExprSyntaxProtocol, _ isLegal: (Character) -> Bool = { _ in false }) -> String? {
        if let illegal = self.first(where: { !($0.isLetter || $0.isNumber || $0 == "_" || isLegal($0)) }) {
            context.diagnose(DiagnosticMsg.stringLiteralContainsIllegalCharacter(expr: expr, char: illegal))
            return nil
        }
        return self
    }
}