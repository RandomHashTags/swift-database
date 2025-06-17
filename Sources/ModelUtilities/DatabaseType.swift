
public enum DatabaseType: String, Sendable {
    case microsoftSQL
    case mongoDB
    case mySQL
    case noSQL
    case oracle
    case postgreSQL

    @inlinable
    public init?(rawValue: String) {
        switch rawValue {
        case "microsoftSQL": self = .microsoftSQL
        case "mongoDB": self = .mongoDB
        case "mySQL": self = .mySQL
        case "noSQL": self = .noSQL
        case "oracle": self = .oracle
        case "postgreSQL": self = .postgreSQL
        default: return nil
        }
    }
}