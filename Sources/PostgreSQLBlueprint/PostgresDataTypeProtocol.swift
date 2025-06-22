
import SQLBlueprint

public protocol PostgresDataTypeProtocol: SQLDataTypeProtocol, ~Copyable {
    var postgresValue: String { get }
}

// MARK: Conformances





// MARK: Standard library

extension Bool: PostgresDataTypeProtocol {
    @inlinable
    public var postgresValue: String {
        self ? "true" : "false"
    }
}
extension String: PostgresDataTypeProtocol {
    @inlinable
    public var postgresValue: String {
        "'\(self)'"
    }
}
extension Substring: PostgresDataTypeProtocol {
    @inlinable
    public var postgresValue: String {
        "'\(self)'"
    }
}

extension Optional: PostgresDataTypeProtocol {
    @inlinable
    public var postgresValue: String {
        switch self {
        case .none:
            return "NULL"
        case .some(let value):
            if let v = value as? PostgresDataTypeProtocol {
                return v.postgresValue
            }
            return "\(value)"
        }
    }
}

extension Int: PostgresDataTypeProtocol {
    @inlinable
    public var postgresValue: String {
        "\(self)"
    }
}
extension Int8: PostgresDataTypeProtocol {
    @inlinable
    public var postgresValue: String {
        "\(self)"
    }
}
extension Int16: PostgresDataTypeProtocol {
    @inlinable
    public var postgresValue: String {
        "\(self)"
    }
}
extension Int32: PostgresDataTypeProtocol {
    @inlinable
    public var postgresValue: String {
        "\(self)"
    }
}
extension Int64: PostgresDataTypeProtocol {
    @inlinable
    public var postgresValue: String {
        "\(self)"
    }
}
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Int128: PostgresDataTypeProtocol {
    @inlinable
    public var postgresValue: String {
        "\(self)"
    }
}

extension UInt: PostgresDataTypeProtocol {
    @inlinable
    public var postgresValue: String {
        "\(self)"
    }
}
extension UInt8: PostgresDataTypeProtocol {
    @inlinable
    public var postgresValue: String {
        "\(self)"
    }
}
extension UInt16: PostgresDataTypeProtocol {
    @inlinable
    public var postgresValue: String {
        "\(self)"
    }
}
extension UInt32: PostgresDataTypeProtocol {
    @inlinable
    public var postgresValue: String {
        "\(self)"
    }
}
extension UInt64: PostgresDataTypeProtocol {
    @inlinable
    public var postgresValue: String {
        "\(self)"
    }
}
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension UInt128: PostgresDataTypeProtocol {
    @inlinable
    public var postgresValue: String {
        "\(self)"
    }
}

// MARK: Foundation

#if canImport(FoundationEssentials) || canImport(Foundation)

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension Date: PostgresDataTypeProtocol {
    @inlinable
    public var postgresValue: String {
        "'\(self)'"
    }
}
extension UUID: PostgresDataTypeProtocol {
    @inlinable
    public var postgresValue: String {
        uuidString
    }
}

#endif