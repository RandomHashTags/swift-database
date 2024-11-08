//
//  PostgresDataType.swift
//
//
//  Created by Evan Anderson on 11/7/24.
//

import SwiftDatabase

public indirect enum PostgresDataType : DatabaseDataType {

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
    case decimal
    /// user-specified precision, exact
    /// 
    /// - Storage Size: variable
    /// - Range: up to 131072 digits before the decimal point; up to 16383 digits after the decimal point
    case numeric
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
    case characterVarying(UInt64)
    /// fixed-length, blank-padded
    case character(UInt64)
    /// variable unlimited length, blank-trimmed
    case bpchar(String)
    /// variable unlimited length
    case text(String)
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
    case interval(field: String, precision: UInt8)

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

    // MARK: Composite types
    // https://www.postgresql.org/docs/current/rowtypes.html
    /// Represents the structure of a raw or record
    case compositeType(values: [(String, PostgresDataType)])

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
    case domain

    // MARK: Object Identifier types
    /// https://www.postgresql.org/docs/current/datatype-oid.html
    /// - Storage Size: 4 bytes
    /// - Storage Type: Unsigned four-byte integer
    case oit(UInt8)

    // MARK: pg_lsn
    // https://www.postgresql.org/docs/current/datatype-pg-lsn.html
    /// Log Sequence Number which is a pointer to a location in the WAL.
    /// 
    /// - Storage Size: 8 bytes
    case lsn
}