
public enum ModelField: Sendable {
    case required(name: String, dataType: String)
    case optional(name: String, dataType: String)
}