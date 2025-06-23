
#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: Field
extension ModelRevision {
    public struct Field: Sendable {
        public let name:String
        public let constraints:[Constraint]
        public package(set) var postgresDataType:PostgresDataType?
        public let defaultValue:String?

        public init(
            name: String,
            constraints: [Constraint] = [.notNull],
            postgresDataType: PostgresDataType? = nil,
            defaultValue: String? = nil
        ) {
            self.name = name
            self.constraints = constraints
            self.postgresDataType = postgresDataType
            self.defaultValue = defaultValue
        }

        public init(
            name: String,
            constraints: [Constraint] = [.notNull],
            postgresDataType: PostgresDataType? = nil,
            defaultValue: Bool
        ) {
            self.init(name: name, constraints: constraints, postgresDataType: postgresDataType, defaultValue: defaultValue ? "true" : "false")
        }

        public init<T: FixedWidthInteger>(
            name: String,
            constraints: [Constraint] = [.notNull],
            postgresDataType: PostgresDataType? = nil,
            defaultValue: T
        ) {
            self.init(name: name, constraints: constraints, postgresDataType: postgresDataType, defaultValue: "\(defaultValue)")
        }
    }
}

// MARK: Field convenience
extension ModelRevision.Field {
    public static func optional(
        name: String,
        postgresDataType: PostgresDataType? = nil,
        defaultValue: String? = nil
    ) -> Self {
        .init(name: name, constraints: [], postgresDataType: postgresDataType, defaultValue: defaultValue)
    }
    public static func required(
        name: String,
        postgresDataType: PostgresDataType? = nil,
        defaultValue: String? = nil
    ) -> Self {
        .init(name: name, constraints: [.notNull], postgresDataType: postgresDataType, defaultValue: defaultValue)
    }
}

extension ModelRevision.Field {
    public static func boolean(
        name: String,
        constraints: [Constraint] = [.notNull],
        defaultValue: Bool
    ) -> Self {
        .init(
            name: name,
            constraints: constraints,
            postgresDataType: .boolean,
            defaultValue: defaultValue
        )
    }
}

extension ModelRevision.Field {
    public static func date(
        name: String,
        constraints: [Constraint] = [.notNull],
        defaultValue: String
    ) -> Self {
        .init(
            name: name,
            constraints: constraints,
            postgresDataType: .date,
            defaultValue: defaultValue
        )
    }

    public static func timestampWithTimeZone(
        name: String,
        precision: UInt8 = 0,
        constraints: [Constraint] = [.notNull],
        defaultValue: String
    ) -> Self {
        .init(
            name: name,
            constraints: constraints,
            postgresDataType: .timestampWithTimeZone(precision: precision),
            defaultValue: defaultValue
        )
    }
    public static func timestampNoTimeZone(
        name: String,
        precision: UInt8 = 0,
        constraints: [Constraint] = [.notNull],
        defaultValue: String
    ) -> Self {
        .init(
            name: name,
            constraints: constraints,
            postgresDataType: .timestampNoTimeZone(precision: precision),
            defaultValue: defaultValue
        )
    }
}

extension ModelRevision.Field {
    public static func int16(
        name: String,
        constraints: [Constraint] = [.notNull],
        defaultValue: Int16
    ) -> Self {
        .init(
            name: name,
            constraints: constraints,
            postgresDataType: .smallint,
            defaultValue: defaultValue
        )
    }
    public static func int32(
        name: String,
        constraints: [Constraint] = [.notNull],
        defaultValue: Int32
    ) -> Self {
        .init(
            name: name,
            constraints: constraints,
            postgresDataType: .integer,
            defaultValue: defaultValue
        )
    }
    public static func int64(
        name: String,
        constraints: [Constraint] = [.notNull],
        defaultValue: Int64
    ) -> Self {
        .init(
            name: name,
            constraints: constraints,
            postgresDataType: .bigint,
            defaultValue: defaultValue
        )
    }
}