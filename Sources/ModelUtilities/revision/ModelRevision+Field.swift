
#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: Column
extension ModelRevision {
    public struct Column: Sendable {
        public static let defaultConstraints:Set<Constraint> = [.notNull]
        public static let defaultBehavior:Set<Behavior> = []

        public let name:String
        public let variableName:String
        public let constraints:Set<Constraint>
        public let defaultValue:String?
        public let behavior:Set<Behavior>

        public package(set) var postgresDataType:PostgresDataType?

        public init(
            name: String,
            variableName: String? = nil,
            constraints: Set<Constraint> = defaultConstraints,
            postgresDataType: PostgresDataType?,
            defaultValue: String? = nil,
            behavior: Set<Behavior> = defaultBehavior
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
            constraints: Set<Constraint> = defaultConstraints,
            postgresDataType: PostgresDataType? = nil,
            defaultValue: Bool,
            behavior: Set<Behavior> = defaultBehavior
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

        public init(
            name: String,
            variableName: String? = nil,
            constraints: Set<Constraint> = defaultConstraints,
            postgresDataType: PostgresDataType? = nil,
            defaultValue: (some FixedWidthInteger)?,
            behavior: Set<Behavior> = defaultBehavior
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





// MARK: Optional
extension ModelRevision.Column {
    public static func optional(
        _ field: ModelRevision.Column
    ) -> Self {
        var constraints = field.constraints
        constraints.remove(.notNull)
        constraints.remove(.primaryKey)
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

// MARK: Primary key
extension ModelRevision.Column {
    public static func primaryKey(
        name: String,
        variableName: String? = nil,
        behavior: Set<Behavior> = defaultBehavior
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

// MARK: Primary key reference
extension ModelRevision.Column {
    public static func primaryKeyReference<Schema: RawModelIdentifier, Table: RawModelIdentifier, FieldName: RawModelIdentifier>(
        referencing: (schema: Schema, table: Table, fieldName: FieldName),
        name: String,
        variableName: String? = nil,
        behavior: Set<Behavior> = defaultBehavior
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
        behavior: Set<Behavior> = defaultBehavior
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

// MARK: Bool
extension ModelRevision.Column {
    public static func bool(
        name: String,
        variableName: String? = nil,
        constraints: Set<Constraint> = defaultConstraints,
        defaultValue: Bool = false,
        behavior: Set<Behavior> = defaultBehavior
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

// MARK: Date
extension ModelRevision.Column {
    public static func date(
        name: String,
        variableName: String? = nil,
        constraints: Set<Constraint> = defaultConstraints,
        defaultValue: String,
        behavior: Set<Behavior> = defaultBehavior
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
}

// MARK: Double
extension ModelRevision.Column {
    public static func double(
        name: String,
        variableName: String? = nil,
        constraints: Set<Constraint> = defaultConstraints,
        defaultValue: Double? = nil,
        behavior: Set<Behavior> = defaultBehavior
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

// MARK: Float
extension ModelRevision.Column {
    public static func float(
        name: String,
        variableName: String? = nil,
        constraints: Set<Constraint> = defaultConstraints,
        defaultValue: Float? = nil,
        behavior: Set<Behavior> = defaultBehavior
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

// MARK: Integers
extension ModelRevision.Column {
    public static func uint8(
        name: String,
        variableName: String? = nil,
        constraints: Set<Constraint> = defaultConstraints,
        defaultValue: UInt8? = nil,
        behavior: Set<Behavior> = defaultBehavior
    ) -> Self {
        .init(
            name: name,
            variableName: variableName,
            constraints: constraints,
            postgresDataType: .bytea,
            defaultValue: defaultValue,
            behavior: behavior
        )
    }
    public static func int16(
        name: String,
        variableName: String? = nil,
        constraints: Set<Constraint> = defaultConstraints,
        defaultValue: Int16? = nil,
        behavior: Set<Behavior> = defaultBehavior
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
        constraints: Set<Constraint> = defaultConstraints,
        defaultValue: Int32? = nil,
        behavior: Set<Behavior> = defaultBehavior
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
        constraints: Set<Constraint> = defaultConstraints,
        defaultValue: Int64? = nil,
        behavior: Set<Behavior> = defaultBehavior
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

// MARK: String
extension ModelRevision.Column {
    public static func string(
        name: String,
        variableName: String? = nil,
        constraints: Set<Constraint> = defaultConstraints,
        defaultValue: String? = nil,
        behavior: Set<Behavior> = defaultBehavior
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
        constraints: Set<Constraint> = defaultConstraints,
        length: UInt64,
        defaultValue: String? = nil,
        behavior: Set<Behavior> = defaultBehavior
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

// MARK: Timestamp
extension ModelRevision.Column {
    public static func timestampNoTimeZone(
        name: String,
        variableName: String? = nil,
        constraints: Set<Constraint> = defaultConstraints,
        precision: UInt8 = 0,
        defaultValue: String? = nil,
        behavior: Set<Behavior> = defaultBehavior
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
    public static func creationTimestamp(
        name: String = "created",
        variableName: String? = nil,
        constraints: Set<Constraint> = defaultConstraints,
        precision: UInt8 = 0,
        behavior: Set<Behavior> = defaultBehavior
    ) -> Self {
        .timestampNoTimeZone(
            name: name,
            variableName: variableName,
            constraints: constraints,
            precision: precision,
            defaultValue: .sqlNow(),
            behavior: behavior.union([
                .dontCreatePreparedStatements,
                .notInsertable,
                .notUpdatable
            ])
        )
    }
    public static func deletionTimestamp(
        name: String = "deleted",
        variableName: String? = nil,
        constraints: Set<Constraint> = defaultConstraints,
        precision: UInt8 = 0,
        behavior: Set<Behavior> = defaultBehavior
    ) -> Self {
        .optional(
            .timestampNoTimeZone(
                name: name,
                variableName: variableName,
                constraints: constraints,
                precision: precision,
                behavior: behavior.union([
                    .dontCreatePreparedStatements,
                    .notInsertable,
                    .notUpdatable,
                    .enablesSoftDeletion
                ])
            )
        )
    }
    public static func restorationTimestamp(
        name: String = "restored",
        variableName: String? = nil,
        constraints: Set<Constraint> = defaultConstraints,
        precision: UInt8 = 0,
        behavior: Set<Behavior> = defaultBehavior
    ) -> Self {
        .optional(
            .timestampNoTimeZone(
                name: name,
                variableName: variableName,
                constraints: constraints,
                precision: precision,
                behavior: behavior.union([
                    .dontCreatePreparedStatements,
                    .notInsertable,
                    .notUpdatable,
                    .restoration
                ])
            )
        )
    }
}
// MARK: Timestamp + zone
extension ModelRevision.Column {
    public static func timestampWithTimeZone(
        name: String,
        variableName: String? = nil,
        constraints: Set<Constraint> = defaultConstraints,
        precision: UInt8 = 0,
        defaultValue: String? = nil,
        behavior: Set<Behavior> = defaultBehavior
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

// MARK: UUID
extension ModelRevision.Column {
    public static func uuid(
        name: String,
        variableName: String? = nil,
        constraints: Set<Constraint> = defaultConstraints,
        defaultValue: String? = nil,
        behavior: Set<Behavior> = defaultBehavior
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