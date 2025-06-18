
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

extension StringLiteralExprSyntax {
    package var text: String { segments.description }
}