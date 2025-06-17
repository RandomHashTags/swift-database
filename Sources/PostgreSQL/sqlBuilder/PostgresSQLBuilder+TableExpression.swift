
extension PostgresSQLBuilder {
    public struct TableExpression: PostgresSQLBuilderComponent {
        public var sql:String

        @inlinable
        init(
            tableSQL: String,
            where: String?,
            groupBy: String?,
            having: String?
        ) {
            var sql = "FROM " + tableSQL
            if let `where` {
                sql += " WHERE " + `where`
            }
            if let groupBy {
                sql += " GROUP BY " + groupBy
            }
            if let having {
                sql += " HAVING " + having
            }
            self.sql = sql
        }
    }
}

// MARK: Table
extension PostgresSQLBuilder.TableExpression {
    @inlinable
    public static func table(
        table: String,
        where: String? = nil,
        groupBy: String? = nil,
        having: String? = nil
    ) -> Self {
        Self(
            tableSQL: table,
            where: `where`,
            groupBy: groupBy,
            having: having
        )
    }
}

// MARK: Cross join
extension PostgresSQLBuilder.TableExpression {
    @inlinable
    public static func crossJoin(t1: String, t2: String) -> Self {
        Self(tableSQL: t1 + " CROSS JOIN " + t2, where: nil, groupBy: nil, having: nil)
    }
}

// MARK: Qualified join
extension PostgresSQLBuilder.TableExpression {
    @inlinable
    public static func qualifiedJoin(
        t1: String,
        joinType: QualifiedJoinType,
        t2: String,
        on: String? = nil,
        using: String? = nil
    ) -> Self {
        var sql = t1 + " " + joinType.sql + " " + t2
        if let on {
            sql += " ON " + on
        } else if let using {
            sql += " USING " + using
        }
        return Self(tableSQL: sql, where: nil, groupBy: nil, having: nil)
    }
}

extension PostgresSQLBuilder.TableExpression {
    public struct QualifiedJoinType: PostgresSQLBuilderComponent {
        public let sql:String

        @inlinable
        init(sql: String) {
            self.sql = sql
        }

        public enum InnerOrOuter: String, Sendable {
            case inner   = "INNER "
            case outer   = "OUTER "
            case omitted = ""
        }
        public enum Width: String, Sendable {
            case left  = "LEFT "
            case right = "RIGHT "
            case full  = "FULL "
        }

        @inlinable
        public static func create(_ width: Width, _ innerOrOuter: InnerOrOuter) -> Self {
            Self(sql: width.rawValue + innerOrOuter.rawValue + "JOIN")
        }
    }
}

// MARK: Cross join
extension PostgresSQLBuilder.TableExpression {
    @inlinable
    public static func crossJoin(
        t1: String,
        t2: String,
        where: String? = nil,
        groupBy: String? = nil,
        having: String? = nil
    ) -> Self {
        Self(
            tableSQL: t1 + " CROSS JOIN " + t2,
            where: `where`,
            groupBy: groupBy,
            having: having
        )
    }
}

// MARK: Inner join
extension PostgresSQLBuilder.TableExpression {
    @inlinable
    public static func innerJoin(
        t1: String,
        t2: String,
        where: String? = nil,
        groupBy: String? = nil,
        having: String? = nil
    ) -> Self {
        Self(
            tableSQL: t1 + " INNER JOIN " + t2,
            where: `where`,
            groupBy: groupBy,
            having: having
        )
    }
}

// MARK: Natural inner join
extension PostgresSQLBuilder.TableExpression {
    @inlinable
    public static func naturalInnerJoin(
        t1: String,
        t2: String,
        where: String? = nil,
        groupBy: String? = nil,
        having: String? = nil
    ) -> Self {
        Self(
            tableSQL: t1 + " NATURAL INNER JOIN " + t2,
            where: `where`,
            groupBy: groupBy,
            having: having
        )
    }
}