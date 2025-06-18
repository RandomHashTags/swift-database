
import SQLBlueprint

public struct PostgresSQLBuilder: SQLBuilderProtocol {
    @usableFromInline
    var unsafeSQL:String

    @inlinable
    public init() {
        unsafeSQL = ""
    }

    public mutating func build() -> String {
        unsafeSQL
    }
}