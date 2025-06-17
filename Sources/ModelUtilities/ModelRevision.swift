
public struct ModelRevision: Sendable {
    public let version:(major: Int, minor: Int, patch: Int)
    public let fields:[(name: String, dataType: String)]

    public init(
        version: (major: Int, minor: Int, patch: Int),
        fields: [(name: String, dataType: String)]
    ) {
        self.version = version
        self.fields = fields
    }
}