
public indirect enum PostgresDataType: DatabaseDataTypeProtocol {

    // MARK: Numeric types
    // https://www.postgresql.org/docs/current/datatype-numeric.html
    /// small-range whole integer
    /// 
    /// - Storage Size: 2 bytes
    /// - Range: -32768 to +32767
    case smallint
    /// typical choice for whole integer
    /// 
    /// - Storage Size: 4 bytes
    /// - Range: -2147483648 to +2147483647
    case integer
    /// large-range whole integer
    /// 
    /// - Storage Size: 8 bytes
    /// - Range: -9223372036854775808 to +9223372036854775807
    case bigint
    /// user-specified precision, exact
    /// 
    /// - Storage Size: variable
    /// - Range: up to 131072 digits before the decimal point; up to 16383 digits after the decimal point
    case decimal(precision: UInt32)
    /// user-specified precision, exact
    /// 
    /// - Storage Size: variable
    /// - Range: up to 131072 digits before the decimal point; up to 16383 digits after the decimal point
    case numeric(precision: UInt32)
    /// variable-precision, inexact
    /// 
    /// - Storage Size: 4 bytes
    /// - Range: 6 decimal digits precision
    case real
    /// variable-precision, inexact
    /// 
    /// - Storage Size: 8 bytes
    /// - Range: 15 decimal digits precision
    case doublePrecision
    /// small autoincrementing integer
    /// 
    /// - Storage Size: 2 bytes
    /// - Range: 1 to 32767
    case smallserial
    /// autoincrementing integer
    /// 
    /// - Storage Size: 4 bytes
    /// - Range: 1 to 2147483647
    case serial
    /// large autoincrementing integer
    /// 
    /// - Storage Size: 8 bytes
    /// - Range: 1 to 9223372036854775807
    case bigserial

    // MARK: Monetary types
    // https://www.postgresql.org/docs/current/datatype-money.html
    /// currency amount
    /// 
    /// - Storage Size: 8 bytes
    /// - Range: -92233720368547758.08 to +92233720368547758.07
    case money

    // MARK: Character types
    // https://www.postgresql.org/docs/current/datatype-character.html
    /// variable-length with limit
    case characterVarying(count: UInt64)
    /// fixed-length, blank-padded
    case character(count: UInt64)
    /// variable unlimited length, blank-trimmed
    case bpchar
    /// variable unlimited length
    case text
    /// single-byte internal type
    /// 
    /// Storage Size: 1 byte
    case char
    /// internal type for object names
    /// 
    /// - Storage Size: 64 bytes
    case name

    // MARK: Binary types
    // https://www.postgresql.org/docs/current/datatype-binary.html
    /// variable-length binary string
    /// 
    /// - Storage Size: 1 or 4 bytes plus the actual binary string
    case bytea

    // MARK: Datetime types
    // https://www.postgresql.org/docs/current/datatype-datetime.html
    /// both date and time (no time zone)
    /// 
    /// - Storage Size: 8 bytes
    /// - Low Value: 4713 BC
    /// - High Value: 294276 AD
    /// - Resolution: 1 microsecond
    case timestampNoTimeZone(precision: UInt8)
    /// both date and time, with time zone
    /// 
    /// - Storage Size: 8 bytes
    /// - Low Value: 4713 BC
    /// - High Value: 294276 AD
    /// - Resolution: 1 microsecond
    case timestampWithTimeZone(precision: UInt8)
    /// date (no time of day)
    /// 
    /// - Storage Size: 4 bytes
    /// - Low Value: 4713 BC
    /// - High Value: 5874897 AD
    /// - Resolution: 1 day
    case date
    /// time of day (no date)
    /// 
    /// - Storage Size: 8 bytes
    /// - Low Value: 00:00:00
    /// - High Value: 24:00:00
    /// - Resolution: 1 microsecond
    case timeNoTimeZone(precision: UInt8)
    /// time of day (no date), with time zone
    /// 
    /// - Storage Size: 12 bytes
    /// - Low Value: 00:00:00+1559
    /// - High Value: 24:00:00-1559
    /// - Resolution: 1 microsecond
    case timeWithTimeZone(precision: UInt8)
    /// time interval
    /// 
    /// - Storage Size: 16 bytes
    /// - Low Value: -178000000 years
    /// - High Value: 178000000 years
    /// - Resolution: 1 microsecond
    //case interval(field: String, precision: UInt8)

    // MARK: Boolean
    /// State of true or false
    /// 
    /// - Storage Size: 1 byte
    case boolean

    // MARK: Geometric types
    // https://www.postgresql.org/docs/current/datatype-geometric.html
    /// Point on a plain (coordinates are stored as `doublePrecision`)
    /// 
    /// - Storage Size: 16 bytes
    /// - Representation: (x,y)
    case point
    /// Infinite line (coordinates are stored as `doublePrecision`)
    /// 
    /// - Storage Size: 24 bytes
    /// - Representation: {A,B,C}
    case line
    /// Finite line segment (coordinates are stored as `doublePrecision`)
    /// 
    /// - Storage Size: 32 bytes
    /// - Representation: [(x1,y1),(x2,y2)]
    case lseg
    /// Rectangular box (coordinates are stored as `doublePrecision`)
    /// 
    /// - Storage Size: 32 bytes
    /// - Representation: (x1,y1),(x2,y2)
    case box
    /// Closed path (similar to polygon; coordinates are stored as `doublePrecision`)
    /// 
    /// - Storage Size: 16 + 16n bytes
    /// - Representation: [(x1,y1),...]
    case pathClosed(points: Int)
    /// Open path (coordinates are stored as `doublePrecision`)
    /// 
    /// - Storage Size: 16 + 16n bytes
    /// - Representation: ((x1,y1),...)
    case pathOpen(points: Int)
    /// Polygon (similar to closed path; coordinates are stored as `doublePrecision`)
    /// 
    /// - Storage Size: 40 + 16n bytes
    /// - Representation: ((x1,y1),...)
    case polygon
    /// Circle (coordinates are stored as `doublePrecision`)
    /// 
    /// - Storage Size: 24 bytes
    /// - Representation: <(x,y),r> (center point and radius)
    case circle

    // MARK: Network Address types
    // https://www.postgresql.org/docs/current/datatype-net-types.html
    /// IPv4 and IPv6 networks
    /// 
    /// - Storage Size: 7 or 19 bytes
    case cidr
    /// IPv4 and IPv6 hosts and networks
    /// 
    /// - Storage Size: 7 or 19 bytes
    case inet
    /// MAC addresses
    /// 
    /// - Storage Size: 6 bytes
    case macaddr
    /// MAC addresses (EUI-64 format)
    /// 
    /// - Storage Size: 8 bytes
    case macaddr8

    // MARK: Bit String types
    // https://www.postgresql.org/docs/current/datatype-bit.html
    case bit(UInt64)
    case bitVarying(UInt64)

    // MARK: Text Search types
    // https://www.postgresql.org/docs/current/datatype-textsearch.html
    case tsvector
    case tsquery

    // MARK: UUID
    // https://www.postgresql.org/docs/current/datatype-uuid.html
    /// As defined by RFC 4122, ISO/IEC 9834-8:2005
    /// 
    /// - Storage Size: 16 bytes
    case uuid

    // MARK: XML
    // https://www.postgresql.org/docs/current/datatype-xml.html
    case xml

    // MARK: JSON
    /// Stored as an exact copy of the input text.
    /// 
    /// In general, most applications should prefer the store JSON data as `jsonb`, unless there are quite specialized needs, such as legacy assumptions about ordering of object keys.
    /// 
    /// Read more: https://www.postgresql.org/docs/current/datatype-json.html
    /// 
    /// - Pros:
    ///   - Faster to input
    ///   - Preserves semantically-insignificant white space between tokens, as well as the order of keys within JSON Objects
    ///   - All key/value pairs are kept, even duplicate object keys
    /// - Cons:
    ///   - Less efficient than `jsonb`
    ///   - Processing functions must reparse on each execution
    ///   - Doesn't support indexing
    case json
    /// Stored in a decomposed binary format
    /// 
    /// Read more: https://www.postgresql.org/docs/current/datatype-json.html
    /// 
    /// - Pros:
    ///   - More efficient than `json`
    ///   - Significantly faster to process, since no reparsing is needed
    ///   - Supports indexing
    /// - Cons:
    ///   - Slightly slower to input due to added conversion overhead
    ///   - Does not preserve white space or the order of object keys
    ///   - Does not keep duplicate object keys; if duplicate keys are specified in the input, only the last value is kept
    case jsonb
    /// Efficiently queries JSON data. Provides binary representation of the parsed SQL/JSON path expression that specifies the items to be retrieved by the path engine from the JSON data for further processing with the SQL/JSON query functions.
    /// 
    /// Read more: https://www.postgresql.org/docs/current/datatype-json.html
    case jsonpath

    // MARK: Arrays
    // https://www.postgresql.org/docs/current/arrays.html
    case array(of: PostgresDataType)
    case arrayWithLimit(of: PostgresDataType, size: UInt64)

    // MARK: Composite types
    // https://www.postgresql.org/docs/current/rowtypes.html
    /// Represents the structure of a raw or record
    //case compositeType(values: [(String, PostgresDataType)])

    // MARK: Range types
    // https://www.postgresql.org/docs/current/rangetypes.html
    /// Range of `integer`
    case int4range
    /// Range of `bigint`
    case int8range
    /// Range of `numeric`
    case numrange
    /// Range of `timestampNoTimeZone`
    case tsrange
    /// Range of `timestampWithTimeZone`
    case tstzrange
    /// Range of `date`
    case daterange

    // MARK: Domain types
    // https://www.postgresql.org/docs/current/domains.html
    /// User-defined data type that is based on another _underlying type_.
    //case domain

    // MARK: Object Identifier types
    /// https://www.postgresql.org/docs/current/datatype-oid.html
    /// - Storage Size: 4 bytes
    /// - Storage Type: Unsigned four-byte integer
    //case oid(UInt8)

    // MARK: pg_lsn
    // https://www.postgresql.org/docs/current/datatype-pg-lsn.html
    /// Log Sequence Number which is a pointer to a location in the write-ahead log stream.
    /// 
    /// - Storage Size: 8 bytes
    case lsn
}

// MARK: Init
extension PostgresDataType {
    public init?(rawValue: String) {
        let values = rawValue.split(separator: "(")
        switch values.first {
        case "smallint":        self = .smallint
        case "integer":         self = .integer
        case "bigint":          self = .bigint
        case "decimal":
            guard let int:UInt32 = Self.parseInt(values) else { return nil }
            self = .decimal(precision: int)
        case "numeric":
            guard let int:UInt32 = Self.parseInt(values) else { return nil }
            self = .numeric(precision: int)
        case "real":            self = .real
        case "doublePrecision": self = .doublePrecision
        case "smallserial":     self = .smallserial
        case "serial":          self = .serial
        case "bigserial":       self = .bigserial

        case "money":           self = .money

        case "characterVarying":
            guard let int:UInt64 = Self.parseInt(values) else { return nil }
            self = .characterVarying(count: int)
        case "character":
            guard let int:UInt64 = Self.parseInt(values) else { return nil }
            self = .character(count: int)
        case "bpchar": self = .bpchar
        case "text":   self = .text
        case "char":   self = .char
        case "name":   self = .name

        case "bytea":  self = .bytea

        case "timestampNoTimeZone":
            guard let int:UInt8 = Self.parseInt(values) else { return nil }
            self = .timeNoTimeZone(precision: int)
        case "timestampWithTimeZone":
            guard let int:UInt8 = Self.parseInt(values) else { return nil }
            self = .timeWithTimeZone(precision: int)
        case "date":
            self = .date
        case "timeNoTimeZone":
            guard let int:UInt8 = Self.parseInt(values) else { return nil }
            self = .timeNoTimeZone(precision: int)
        case "timeWithTimeZone":
            guard let int:UInt8 = Self.parseInt(values) else { return nil }
            self = .timeWithTimeZone(precision: int)

        case "boolean":
            self = .boolean

        case "point": self = .point
        case "line": self = .line
        case "lseg": self = .lseg
        case "box": self = .box
        case "pathOpen": self = .pathOpen(points: 0) // TODO: fix
        case "pathClosed": self = .pathClosed(points: 0) // TODO: fix
        case "circle": self = .circle

        case "cidr": self = .cidr
        case "inet": self = .inet
        case "macaddr": self = .macaddr
        case "macaddr8": self = .macaddr8
        case "bit":
            guard let int:UInt64 = Self.parseInt(values) else { return nil }
            self = .bit(int)
        case "bitVarying":
            guard let int:UInt64 = Self.parseInt(values) else { return nil }
            self = .bitVarying(int)

        case "tsvector": self = .tsvector
        case "tsquery": self = .tsquery

        case "uuid": self = .uuid
        
        case "xml": self = .xml

        case "json": self = .json
        case "jsonb": self = .jsonb
        case "jsonpath": self = .jsonpath

        case "array":
            let inner = String(rawValue[rawValue.index(rawValue.startIndex, offsetBy: 6)..<rawValue.index(before: rawValue.endIndex)])
            guard let data = Self.init(rawValue: inner) else { return nil }
            self = .array(of: data)
        case "arrayWithLimit":
            let rvValues = rawValue.split(separator: ",")
            guard let rv = rvValues.first else { return nil }
            let inner = String(rv[rv.index(rv.startIndex, offsetBy: 6)..<rv.endIndex])
            guard let data = Self.init(rawValue: inner),
                    let s = rvValues.last,
                    let size = UInt64(s)
            else {
                return nil
            }
            self = .arrayWithLimit(of: data, size: size)

        case "int4range": self = .int4range
        case "int8range": self = .int8range
        case "numrange": self = .numrange
        case "tsrange": self = .tsrange
        case "tstzrange": self = .tstzrange
        case "daterange": self = .daterange

        case "lsn": self = .lsn

        default:
            return nil
        }
    }

    @inlinable
    static func parseInt<T: FixedWidthInteger>(_ values: [Substring]) -> T? {
        guard var value = values.last?.split(separator: ":").last else { return nil }
        value.removeAll(where: { !$0.isNumber })
        return T(value)
    }
}

// MARK: Name
extension PostgresDataType {
    @inlinable
    public var name: String {
        switch self {
        case .smallint: "smallint"
        case .integer: "integer"
        case .bigint: "bigint"
        case .decimal: "decimal"
        case .numeric(let precision): "numeric(\(precision))"
        case .real: "real"
        case .doublePrecision: "double precision"
        case .smallserial: "smallserial"
        case .serial: "serial"
        case .bigserial: "bigserial"

        case .money: "money"

        case .characterVarying(let count): "character varying(\(count))"
        case .character(let count): "character(\(count))"
        case .bpchar: "bpchar"
        case .text: "text"
        case .char: "char"
        case .name: "name"

        case .bytea: "bytea"

        case .timestampNoTimeZone(let precision): "timestamp(\(precision))"
        case .timestampWithTimeZone(let precision): "timestamp(\(precision)) with time zone"
        case .date: "date"
        case .timeNoTimeZone(let precision): "time(\(precision))"
        case .timeWithTimeZone(let precision): "time(\(precision)) with time zone"
        //case .interval(let field, let precision): "interval" // TODO: fix

        case .boolean: "boolean"

        case .point: "point"
        case .line: "line"
        case .lseg: "lseg"
        case .box: "box"
        case .pathOpen, .pathClosed: "path"
        case .polygon: "polygon"
        case .circle: "circle"

        case .cidr: "cidr"
        case .inet: "inet"
        case .macaddr: "macaddr"
        case .macaddr8: "macaddr8"

        case .bit(let count): "bit(\(count))"
        case .bitVarying(let count): "bit varying(\(count))"

        case .tsvector: "tsvector"
        case .tsquery: "tsquery"

        case .uuid: "uuid"

        case .xml: "xml"

        case .json: "json"
        case .jsonb: "jsonb"
        case .jsonpath: "jsonpath"

        case .array(let dataType): dataType.name + "[]"
        case .arrayWithLimit(let dataType, let size): dataType.name + "[\(size)]"

        case .int4range: "int4range"
        case .int8range: "int8range"
        case .numrange: "numrange"
        case .tsrange: "tsrange"
        case .tstzrange: "tstzrange"
        case .daterange: "daterange"

        //case .oid: "oid"

        case .lsn: "pg_lsn"
        }
    }
}

// MARK: Swift data type
extension PostgresDataType {
    @inlinable
    public var swiftDataType: String {
        switch self {
        case .smallint: "Int16"
        case .integer:  "Int32"
        case .bigint:   "Int64"
        case .doublePrecision: "Double"
        case .smallserial: "Int16"
        case .serial: "Int32"
        case .bigserial: "Int64"

        case .money: "Int64"
        case .characterVarying, .character, .bpchar, .text: "String"
        case .char: "UInt8"
        case .name: "String"

        case .bytea: "[UInt8]" // TODO: fix?

        case .timestampNoTimeZone, .timestampWithTimeZone: "String" // TODO: fix
        case .date: "Date"
        case .timeNoTimeZone, .timeWithTimeZone: "String" // TODO: fix

        case .boolean: "Bool"

        case .point: "(x: Double, y: Double)"
        case .line: "(a: Double, b: Double, c: Double)"
        case .lseg: "String" // TODO: fix
        case .box: "String" // TODO: fix
        case .pathClosed: "String" // TODO: fix
        case .pathOpen: "String" // TODO: fix
        case .polygon: "String" // TODO: fix
        case .circle: "String" // TODO: fix

        case .cidr: "String" // TODO: fix
        case .inet: "String" // TODO: fix
        case .macaddr: "InlineArray<6, UInt8>"
        case .macaddr8: "InlineArray<8, UInt8>"
        case .bit: "String" // TODO: fix?
        case .bitVarying: "String" // TODO: fix?

        case .tsvector: "String" // TODO: fix
        case .tsquery: "String" // TODO: fix

        case .uuid: "UUID"

        case .xml: "String"

        case .json: "String"
        case .jsonb: "String"
        case .jsonpath: "String"

        case .array(let data): "[\(data.swiftDataType)]"
        case .arrayWithLimit(let data, let size): "[\(data.swiftDataType)]"

        case .int4range: "(Int32, Int32)"
        case .int8range: "(Int64, Int64)"
        case .numrange:  "(Double, Double)" // TOOD: fix
        case .tsrange:   "(String, String)" // TODO: fix?
        case .tstzrange: "(String, String)" // TODO: fix?
        case .daterange: "(Date, Date)"

        case .lsn: "String" // TODO: fix?

        default: "String" // TODO: fix
        }
    }
}