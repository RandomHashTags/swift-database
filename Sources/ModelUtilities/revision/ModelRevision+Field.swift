
#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: Field
extension ModelRevision {
    public struct Field: Sendable {
        public let name:String
        public let variableName:String
        public let constraints:[Constraint]
        public package(set) var postgresDataType:PostgresDataType?
        public let defaultValue:String?

        public let autoCreatePreparedStatements:Bool

        public init(
            name: String,
            variableName: String? = nil,
            constraints: [Constraint] = [.notNull],
            postgresDataType: PostgresDataType?,
            defaultValue: String? = nil,
            autoCreatePreparedStatements: Bool = true
        ) {
            self.name = name
            self.variableName = variableName ?? name
            self.constraints = constraints
            self.postgresDataType = postgresDataType
            self.defaultValue = defaultValue
            self.autoCreatePreparedStatements = autoCreatePreparedStatements
        }

        public init(
            name: String,
            variableName: String? = nil,
            constraints: [Constraint] = [.notNull],
            postgresDataType: PostgresDataType? = nil,
            defaultValue: Bool,
            autoCreatePreparedStatements: Bool
        ) {
            self.init(
                name: name,
                variableName: variableName,
                constraints: constraints,
                postgresDataType: postgresDataType,
                defaultValue: defaultValue ? "true" : "false",
                autoCreatePreparedStatements: autoCreatePreparedStatements
            )
        }

        public init<T: FixedWidthInteger>(
            name: String,
            variableName: String? = nil,
            constraints: [Constraint] = [.notNull],
            postgresDataType: PostgresDataType? = nil,
            defaultValue: T?,
            autoCreatePreparedStatements: Bool
        ) {
            let dv:String?
            if let defaultValue {
                dv = "\(defaultValue)"
            } else {
                dv = nil
            }
            self.init(
                name: name,
                variableName: variableName,
                constraints: constraints,
                postgresDataType: postgresDataType,
                defaultValue: dv,
                autoCreatePreparedStatements: autoCreatePreparedStatements
            )
        }
    }
}

// MARK: Field convenience
extension ModelRevision.Field {
    public static func optional(
        _ field: ModelRevision.Field
    ) -> Self {
        var constraints = field.constraints
        let disallowed:Set<Constraint> = [.notNull, .primaryKey]
        while let i = constraints.firstIndex(where: { disallowed.contains($0) }) {
            constraints.remove(at: i)
        }
        return .init(
            name: field.name,
            variableName: field.variableName,
            constraints: constraints,
            postgresDataType: field.postgresDataType,
            defaultValue: field.defaultValue,
            autoCreatePreparedStatements: field.autoCreatePreparedStatements
        )
    }
}

extension ModelRevision.Field {
    public static func bool(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        defaultValue: Bool = false,
        autoCreatePreparedStatements: Bool = true
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .boolean,
            defaultValue: defaultValue,
            autoCreatePreparedStatements: autoCreatePreparedStatements
        )
    }
}

extension ModelRevision.Field {
    public static func date(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        defaultValue: String,
        autoCreatePreparedStatements: Bool = true
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .date,
            defaultValue: defaultValue,
            autoCreatePreparedStatements: autoCreatePreparedStatements
        )
    }

    public static func timestampNoTimeZone(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        precision: UInt8 = 0,
        defaultValue: String? = nil,
        autoCreatePreparedStatements: Bool = true
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .timestampNoTimeZone(precision: precision),
            defaultValue: defaultValue,
            autoCreatePreparedStatements: autoCreatePreparedStatements
        )
    }
    public static func timestampWithTimeZone(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        precision: UInt8 = 0,
        defaultValue: String? = nil,
        autoCreatePreparedStatements: Bool = true
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .timestampWithTimeZone(precision: precision),
            defaultValue: defaultValue,
            autoCreatePreparedStatements: autoCreatePreparedStatements
        )
    }
}

extension ModelRevision.Field {
    public static func int16(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        defaultValue: Int16? = nil,
        autoCreatePreparedStatements: Bool = true
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .smallint,
            defaultValue: defaultValue,
            autoCreatePreparedStatements: autoCreatePreparedStatements
        )
    }
    public static func int32(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        defaultValue: Int32? = nil,
        autoCreatePreparedStatements: Bool = true
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .integer,
            defaultValue: defaultValue,
            autoCreatePreparedStatements: autoCreatePreparedStatements
        )
    }
    public static func int64(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        defaultValue: Int64? = nil,
        autoCreatePreparedStatements: Bool = true
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .bigint,
            defaultValue: defaultValue,
            autoCreatePreparedStatements: autoCreatePreparedStatements
        )
    }
}

extension ModelRevision.Field {
    public static func string(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        defaultValue: String? = nil,
        autoCreatePreparedStatements: Bool = true
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .text,
            defaultValue: defaultValue,
            autoCreatePreparedStatements: autoCreatePreparedStatements
        )
    }
    public static func string(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        length: UInt64,
        defaultValue: String? = nil,
        autoCreatePreparedStatements: Bool = true
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .characterVarying(count: length),
            defaultValue: defaultValue,
            autoCreatePreparedStatements: autoCreatePreparedStatements
        )
    }
}