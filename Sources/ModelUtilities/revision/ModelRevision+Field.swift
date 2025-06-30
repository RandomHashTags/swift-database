
#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: Column
extension ModelRevision {
    public struct Column: Sendable {
        public static let defaultBehavior:Set<Behavior> = []

        public let name:String
        public let variableName:String
        public let constraints:[Constraint]
        public package(set) var postgresDataType:PostgresDataType?
        public let defaultValue:String?

        public let behavior:Set<Behavior>

        public init(
            name: String,
            variableName: String? = nil,
            constraints: [Constraint] = [.notNull],
            postgresDataType: PostgresDataType?,
            defaultValue: String? = nil,
            behavior: Set<Behavior> = Self.defaultBehavior
        ) {
            self.name = name
            self.variableName = variableName ?? name
            self.constraints = constraints
            self.postgresDataType = postgresDataType
            self.defaultValue = defaultValue
            self.behavior = behavior
        }

        public init(
            name: String,
            variableName: String? = nil,
            constraints: [Constraint] = [.notNull],
            postgresDataType: PostgresDataType? = nil,
            defaultValue: Bool,
            behavior: Set<Behavior> = Self.defaultBehavior
        ) {
            self.init(
                name: name,
                variableName: variableName,
                constraints: constraints,
                postgresDataType: postgresDataType,
                defaultValue: defaultValue ? "true" : "false",
                behavior: behavior
            )
        }

        public init<T: FixedWidthInteger>(
            name: String,
            variableName: String? = nil,
            constraints: [Constraint] = [.notNull],
            postgresDataType: PostgresDataType? = nil,
            defaultValue: T?,
            behavior: Set<Behavior> = Self.defaultBehavior
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
                behavior: behavior
            )
        }
    }
}

// MARK: Behavior
extension ModelRevision.Column {
    /// Settings that help automate functionality and the contents of the macro expansion for a model.
    public enum Behavior: String, Hashable, Sendable {
        /// Whether or not prepared statements are auto-generated for the field
        case dontCreatePreparedStatements

        /// Whether or not migrations are auto-generated for the field
        case dontCreateMigrations

        /// Indicates this field enables soft deletion of the model.
        /// 
        /// Soft-deleted models still exist in the database after deletion (unless force-deleted) and will not be returned by queries implictly.
        case enablesSoftDeletion

        /// Whether or not this field is absent for the auto-generated prepared statements relating to inserting a model
        case notInsertable

        /// Whether or not this field is absent for the auto-generated prepared statements relating to updating the model
        case notUpdatable

        /// Indicates this field records when the model was restored.
        /// 
        /// Models require a field that enables soft deletion for this to work properly.
        case restoration

        /// An SQL value that is set for this field when the model is updated
        //case onUpdateValue(String?)
    }
}

// MARK: Column convenience
extension ModelRevision.Column {
    public static func optional(
        _ field: ModelRevision.Column
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
            behavior: field.behavior
        )
    }
}

extension ModelRevision.Column {
    public static func primaryKey(
        name: String,
        variableName: String? = nil,
        behavior: Set<Behavior> = Self.defaultBehavior
    ) -> Self {
        return .init(
            name: name,
            variableName: variableName,
            constraints: [.primaryKey],
            postgresDataType: .bigserial,
            defaultValue: nil,
            behavior: behavior.union([.notInsertable, .notUpdatable])
        )
    }
}

extension ModelRevision.Column {
    public static func primaryKeyReference<Schema: RawModelIdentifier, Table: RawModelIdentifier, FieldName: RawModelIdentifier>(
        referencing: (schema: Schema, table: Table, fieldName: FieldName),
        name: String,
        variableName: String? = nil,
        behavior: Set<Behavior> = Self.defaultBehavior
    ) -> Self {
        return primaryKeyReference(
            referencing: (referencing.schema.rawValue, referencing.table.rawValue, referencing.fieldName.rawValue),
            name: name,
            variableName: variableName,
            behavior: behavior
        )
    }
    public static func primaryKeyReference(
        referencing: (schema: String, table: String, fieldName: String),
        name: String,
        variableName: String? = nil,
        behavior: Set<Behavior> = Self.defaultBehavior
    ) -> Self {
        return .init(
            name: name,
            variableName: variableName,
            constraints: [
                .notNull,
                .references(
                    schema: referencing.schema,
                    table: referencing.table,
                    fieldName: referencing.fieldName
                )
            ],
            postgresDataType: .bigserial,
            defaultValue: nil,
            behavior: behavior
        )
    }
}

extension ModelRevision.Column {
    public static func bool(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        defaultValue: Bool = false,
        behavior: Set<Behavior> = Self.defaultBehavior
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .boolean,
            defaultValue: defaultValue,
            behavior: behavior
        )
    }
}

extension ModelRevision.Column {
    public static func date(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        defaultValue: String,
        behavior: Set<Behavior> = Self.defaultBehavior
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .date,
            defaultValue: defaultValue,
            behavior: behavior
        )
    }

    public static func timestampNoTimeZone(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        precision: UInt8 = 0,
        defaultValue: String? = nil,
        behavior: Set<Behavior> = Self.defaultBehavior
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .timestampNoTimeZone(precision: precision),
            defaultValue: defaultValue,
            behavior: behavior
        )
    }
    public static func timestampWithTimeZone(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        precision: UInt8 = 0,
        defaultValue: String? = nil,
        behavior: Set<Behavior> = Self.defaultBehavior
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .timestampWithTimeZone(precision: precision),
            defaultValue: defaultValue,
            behavior: behavior
        )
    }
}

extension ModelRevision.Column {
    public static func double(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        defaultValue: Double? = nil,
        behavior: Set<Behavior> = Self.defaultBehavior
    ) -> Self {
        let dv:String?
        if let defaultValue {
            dv = "\(defaultValue)"
        } else {
            dv = nil
        }
        return .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .doublePrecision,
            defaultValue: dv,
            behavior: behavior
        )
    }
}

extension ModelRevision.Column {
    public static func float(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        defaultValue: Float? = nil,
        behavior: Set<Behavior> = Self.defaultBehavior
    ) -> Self {
        let dv:String?
        if let defaultValue {
            dv = "\(defaultValue)"
        } else {
            dv = nil
        }
        return .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .real,
            defaultValue: dv,
            behavior: behavior
        )
    }
}

extension ModelRevision.Column {
    public static func int16(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        defaultValue: Int16? = nil,
        behavior: Set<Behavior> = Self.defaultBehavior
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .smallint,
            defaultValue: defaultValue,
            behavior: behavior
        )
    }
    public static func int32(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        defaultValue: Int32? = nil,
        behavior: Set<Behavior> = Self.defaultBehavior
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .integer,
            defaultValue: defaultValue,
            behavior: behavior
        )
    }
    public static func int64(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        defaultValue: Int64? = nil,
        behavior: Set<Behavior> = Self.defaultBehavior
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .bigint,
            defaultValue: defaultValue,
            behavior: behavior
        )
    }
}

extension ModelRevision.Column {
    public static func string(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        defaultValue: String? = nil,
        behavior: Set<Behavior> = Self.defaultBehavior
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .text,
            defaultValue: defaultValue,
            behavior: behavior
        )
    }
    public static func string(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        length: UInt64,
        defaultValue: String? = nil,
        behavior: Set<Behavior> = Self.defaultBehavior
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .characterVarying(count: length),
            defaultValue: defaultValue,
            behavior: behavior
        )
    }
}

extension ModelRevision.Column {
    public static func uuid(
        name: String,
        variableName: String? = nil,
        constraints: [Constraint] = [.notNull],
        defaultValue: String? = nil,
        behavior: Set<Behavior> = Self.defaultBehavior
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .uuid,
            defaultValue: defaultValue,
            behavior: behavior
        )
    }
}