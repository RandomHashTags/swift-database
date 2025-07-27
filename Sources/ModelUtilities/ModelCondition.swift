
public struct ModelCondition: Sendable {
    public let name:String
    public let firstCondition:Value
    public let additionalConditions: [(joiningOperator: JoiningOperator, condition: Value)]

    @inlinable
    public init(
        name: String,
        firstCondition: Value,
        additionalConditions: [(joiningOperator: JoiningOperator, condition: Value)] = []
    ) {
        self.name = name
        self.firstCondition = firstCondition
        self.additionalConditions = additionalConditions
    }

    @inlinable
    public var sql: String {
        firstCondition.sql + (additionalConditions.isEmpty ? "" : " " + additionalConditions.map({ $0.joiningOperator.sql + " " + $0.condition.sql }).joined(separator: " "))
    }
}

// MARK: Value
extension ModelCondition {
    public struct Value: Sendable {
        public let field:String
        public let `operator`:Operator
        public let value:String

        @inlinable
        public init(
            field: String,
            operator: Operator,
            value: some StringProtocol
        ) {
            self.field = field
            self.operator = `operator`
            self.value = "'\(value)'"
        }

        @inlinable
        public init(
            field: String,
            operator: Operator,
            value: some FixedWidthInteger
        ) {
            self.field = field
            self.operator = `operator`
            self.value = String(describing: value)
        }

        @inlinable
        public var sql: String {
            field + " " + `operator`.sql + " " + value
        }
    }
}

// MARK: Operators
extension ModelCondition {
    public enum JoiningOperator: String, Sendable {
        case and
        case or

        @inlinable
        public var sql: String {
            switch self {
            case .and: "AND"
            case .or:  "OR"
            }
        }
    }
    public enum Operator: String, Sendable {
        case equal
        case notEqual

        case greaterThan
        case greaterThanOrEqualTo

        case lessThan
        case lessThanOrEqualTo

        case not

        case between
        case `in`
        case isNull
        case isNotNull
        case like
        case notLike

        @inlinable
        public var sql: String {
            switch self {
            case .equal:                "="
            case .notEqual:             "!="

            case .greaterThan:          ">"
            case .greaterThanOrEqualTo: ">="

            case .lessThan:             "<"
            case .lessThanOrEqualTo:    "<="

            case .not:                  "NOT"

            case .between:              "BETWEEN"
            case .`in`:                 "IN"
            case .isNull:               "IS NULL"
            case .isNotNull:            "IS NOT NULL"
            case .like:                 "LIKE"
            case .notLike:              "NOT LIKE"
            }
        }
    }
}