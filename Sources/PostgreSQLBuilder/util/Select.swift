
import PostgreSQLBlueprint

extension PostgresSQLBuilder {
    public struct Select: PostgresSQLBuilderComponent {
        public let sql:String

        @inlinable
        public init<let listCount: Int, let sortSpecificationCount: Int>(
            list: InlineArray<listCount, String>,
            from table: String?,
            tableAlias: String? = nil,
            sortSpecification: InlineArray<sortSpecificationCount, String>
        ) {
            var sql = "SELECT "
            if !list.isEmpty {
                sql += list[0]
                if listCount > 1 {
                    let oneBeforeEnd = listCount-1
                    var i = 0
                    while i < oneBeforeEnd {
                        sql += ", " + list[i]
                        i += 1
                    }
                    sql += " + " + list[i]
                }
            }
            if let table {
                sql += " FROM " + table
            }
            if let tableAlias {
                sql += " AS " + tableAlias
            }
            self.sql = sql
        }
    }
}

// MARK: Convenience
extension PostgresSQLBuilder {
    @inlinable
    public mutating func select<let listCount: Int,  let sortSpecificationCount: Int>(
        list: InlineArray<listCount, String>,
        from table: String?,
        tableAlias: String? = nil,
        sortSpecification: InlineArray<sortSpecificationCount, String>
    ) {
        unsafeSQL = Select(list: list, from: table, tableAlias: tableAlias, sortSpecification: sortSpecification).sql
    }
}