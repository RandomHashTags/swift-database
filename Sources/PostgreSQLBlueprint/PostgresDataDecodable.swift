
import ModelUtilities

public protocol PostgresDataDecodable: Sendable, ~Copyable {
    static func postgresDecode(
        _ value: String,
        as type: PostgresDataType
    ) throws -> Self?
}

// MARK: Extensions
extension Int16: PostgresDataDecodable {
    @inlinable
    public static func postgresDecode(_ value: String, as type: PostgresDataType) throws -> Self? {
        switch type {
        case .smallint, .smallserial,
                .char:
            Self(value)
        default:
            nil
        }
    }
}

extension Int32: PostgresDataDecodable {
    @inlinable
    public static func postgresDecode(_ value: String, as type: PostgresDataType) throws -> Self? {
        switch type {
        case .smallint, .integer, .smallserial, .serial,
                .char:
            Self(value)
        default:
            nil
        }
    }
}

extension Int64: PostgresDataDecodable {
    @inlinable
    public static func postgresDecode(_ value: String, as type: PostgresDataType) throws -> Self? {
        switch type {
        case .smallint, .integer, .bigint, .smallserial, .serial, .bigserial,
                .money,
                .char:
            Self(value)
        default:
            nil
        }
    }
}