
import ModelUtilities
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: Parse field
extension ModelRevision.Field {
    struct Compiled: Equatable {
        let expr:ExprSyntax
        var columnName:String
        var variableName:String
        var constraints:[Constraint] = [.notNull]
        var postgresDataType:PostgresDataType? = nil
        var defaultValue:String? = nil
        var behavior:Set<ModelRevision.Field.Behavior>

        var isRequired: Bool {
            constraints.contains(.primaryKey) || constraints.contains(.notNull)
        }

        var formattedName: String {
            columnName[columnName.startIndex].uppercased() + columnName[columnName.index(after: columnName.startIndex)...]
        }
    }
    static func parse(
        context: some MacroExpansionContext,
        expr: ExprSyntax
    ) -> Compiled? {
        guard let functionCall = expr.functionCall else {
            context.diagnose(DiagnosticMsg.expectedFunctionCallExpr(expr: expr))
            return nil
        }
        var constraints:[ModelRevision.Field.Constraint] = [.notNull]
        var postgresDataType:PostgresDataType? = nil
        var behavior:Set<ModelRevision.Field.Behavior> = ModelRevision.Field.defaultBehavior
        switch functionCall.calledExpression.memberAccess?.declName.baseName.text {
        case "init":
            break
        case "optional":
            if let inner = functionCall.arguments.first?.expression, var v = parse(context: context, expr: inner) {
                let disallowed:Set<Constraint> = [.notNull, .primaryKey]
                v.constraints.removeAll(where: { disallowed.contains($0) })
                return v
            }
        case "primaryKey":
            postgresDataType = .bigserial
            constraints = [.primaryKey]
            behavior.formUnion([.notInsertable, .notUpdatable])
        case "primaryKeyReference":
            postgresDataType = .bigserial
            if let referencing = functionCall.arguments.first(where: { $0.label?.text == "referencing" }) {
                if let tuple = referencing.expression.tuple, tuple.elements.count == 3 {
                    var schema:String? = nil
                    var table:String? = nil
                    var fieldName:String? = nil
                    for (i, element) in tuple.elements.enumerated() {
                        switch i {
                        case 0: schema = element.expression.legalRawModelIdentifier(context: context)
                        case 1: table = element.expression.legalRawModelIdentifier(context: context)
                        case 2: fieldName = element.expression.legalRawModelIdentifier(context: context)
                        default: break
                        }
                    }
                    guard let schema, let table, let fieldName else {
                        break
                    }
                    constraints = [.notNull, .references(schema: schema, table: table, fieldName: fieldName)]
                }
            }
        case "bool":
            postgresDataType = .boolean
        case "date":
            postgresDataType = .date
        case "double":
            postgresDataType = .doublePrecision
        case "float":
            postgresDataType = .real
        case "int16":
            postgresDataType = .smallint
        case "int32":
            postgresDataType = .integer
        case "int64":
            postgresDataType = .bigint
        case "string":
            postgresDataType = .text
            if let length = functionCall.arguments.first(where: { $0.label?.text == "length" }) {
                guard let literal = length.expression.as(IntegerLiteralExprSyntax.self)?.literal.text,
                        let value = UInt64(literal)
                else {
                    return nil
                }
                postgresDataType = .characterVarying(count: value)
            }
        case "timestampNoTimeZone":
            postgresDataType = .timestampNoTimeZone(precision: 0)
            if let precision = functionCall.arguments.first(where: { $0.label?.text == "precision" }) {
                guard let literal = precision.expression.as(IntegerLiteralExprSyntax.self)?.literal.text,
                        let value = UInt8(literal)
                else {
                    return nil
                }
                postgresDataType = .timestampNoTimeZone(precision: value)
            }
        case "timestampWithTimeZone":
            postgresDataType = .timestampWithTimeZone(precision: 0)
            if let precision = functionCall.arguments.first(where: { $0.label?.text == "precision" }) {
                guard let literal = precision.expression.as(IntegerLiteralExprSyntax.self)?.literal.text,
                        let value = UInt8(literal)
                else {
                    return nil
                }
                postgresDataType = .timestampWithTimeZone(precision: value)
            }
        case "uuid":
            postgresDataType = .uuid
        default:
            break
        }
        return parse(
            context: context,
            expr: expr,
            functionCall: functionCall,
            constraints: constraints,
            behavior: behavior,
            postgresDataType: postgresDataType
        )
    }
    private static func parse(
        context: some MacroExpansionContext,
        expr: ExprSyntax,
        functionCall: FunctionCallExprSyntax,
        constraints: [Constraint],
        behavior: Set<ModelRevision.Field.Behavior>,
        postgresDataType: PostgresDataType?
    ) -> Compiled? {
        var columnName:String? = nil
        var variableName:String? = nil
        var constraints = constraints
        var postgresDataType = postgresDataType
        var defaultValue:String? = nil
        var behavior:Set<ModelRevision.Field.Behavior> = behavior
        for arg in functionCall.arguments {
            switch arg.label?.text {
            case "name":
                columnName = arg.expression.legalRawModelIdentifier(context: context)
            case "variableName":
                variableName = arg.expression.legalRawModelIdentifier(context: context)
            case "constraints":
                if let array = arg.expression.array?.elements {
                    constraints = array.compactMap({ .parse(context: context, expr: $0.expression) })
                } else {
                    constraints = []
                }
            case "postgresDataType":
                if let s = arg.expression.memberAccess?.declName.baseName.text {
                    postgresDataType = .init(rawValue: s)
                } else if var s = arg.expression.functionCall?.description {
                    s.removeFirst()
                    postgresDataType = .init(rawValue: s)
                }
            case "defaultValue":
                if let s = arg.expression.stringLiteral?.legalText(context: context)
                        ?? arg.expression.as(BooleanLiteralExprSyntax.self)?.literal.text
                        ?? arg.expression.integerLiteral?.literal.text {
                    defaultValue = s
                } else if let s = arg.expression.functionCall?.calledExpression.memberAccess?.declName.baseName.text {
                    switch s {
                    case "sqlEpoch":
                        defaultValue = "'epoch()'"
                    case "sqlInfinity":
                        defaultValue = "'infinity()'"
                    case "sqlNegativeInfinity":
                        defaultValue = "'-infinity()'"
                    case "sqlNow":
                        defaultValue = "'now()'"
                    case "sqlToday":
                        defaultValue = "'today()'"
                    case "sqlTomorrow":
                        defaultValue = "'tomorrow()'"
                    case "sqlYesterday":
                        defaultValue = "'yesterday()'"
                    case "allballs":
                        defaultValue = "'allballs()'"
                    default:
                        break
                    }
                }
            case "behavior":
                if let array = arg.expression.array?.elements {
                    behavior.formUnion(Set(array.compactMap({
                        guard let s = $0.expression.memberAccess?.declName.baseName.text else { return nil }
                        return .init(rawValue: s)
                    })))
                } else {
                    context.diagnose(DiagnosticMsg.expectedArrayExpr(expr: arg.expression))
                }
            default:
                break
            }
        }
        guard let columnName else { return nil }
        return .init(
            expr: expr,
            columnName: columnName,
            variableName: variableName ?? columnName,
            constraints: constraints,
            postgresDataType: postgresDataType,
            defaultValue: defaultValue,
            behavior: behavior
        )
    }
}

// MARK: Parse field constraint
extension ModelRevision.Field.Constraint {
    static func parse(
        context: some MacroExpansionContext,
        expr: ExprSyntax
    ) -> Self? {
        guard let member = expr.memberAccess else {
            if let functionCall = expr.functionCall {
                switch functionCall.calledExpression.memberAccess?.declName.baseName.text {
                case "check":
                    var leftFieldName:String? = nil
                    var rightFieldName:String? = nil
                    for arg in functionCall.arguments {
                        switch arg.label?.text {
                        case "leftFieldName":
                            leftFieldName = arg.expression.legalRawModelIdentifier(context: context)
                        case "rightFieldName":
                            rightFieldName = arg.expression.legalRawModelIdentifier(context: context)
                        default:
                            break
                        }
                    }
                    guard let leftFieldName, let rightFieldName else { return nil }
                    return .check(leftFieldName: leftFieldName, rightFieldName: rightFieldName)
                case "references":
                    var schema:String? = nil
                    var table:String? = nil
                    var fieldName:String? = nil
                    for arg in functionCall.arguments {
                        switch arg.label?.text {
                        case "schema":
                            schema = arg.expression.legalRawModelIdentifier(context: context)
                        case "table":
                            table = arg.expression.legalRawModelIdentifier(context: context)
                        case "fieldName":
                            fieldName = arg.expression.legalRawModelIdentifier(context: context)
                        default:
                            break
                        }
                    }
                    guard let schema, let table, let fieldName else { return nil }
                    return .references(schema: schema, table: table, fieldName: fieldName)
                default:
                    context.diagnose(Diagnostic(node: expr, message: DiagnosticMsg.failedToParseModelRevisionFieldConstraint()))
                    return nil
                }
            }
            context.diagnose(DiagnosticMsg.expectedFunctionCallOrMemberAccessExpr(expr: expr))
            return nil
        }
        switch member.declName.baseName.text {
        case "notNull":
            return .notNull
        case "unique":
            return .unique
        case "nullsNotDistinct":
            return .nullsNotDistinct
        case "primaryKey":
            return .primaryKey
        default:
            context.diagnose(Diagnostic(node: expr, message: DiagnosticMsg.failedToParseModelRevisionFieldConstraint()))
            return nil
        }
    }
}

// MARK: Extensions
extension Array where Element == ModelRevision.Field.Compiled {
    var primaryKey: Element? {
        self.first(where: { $0.constraints.contains(.primaryKey) })
    }

    var insertableFields: Self {
        self.filter { !$0.behavior.contains(.notInsertable) }
    }

    var updatableFields: Self {
        self.filter { !$0.behavior.contains(.notUpdatable) }
    }
}