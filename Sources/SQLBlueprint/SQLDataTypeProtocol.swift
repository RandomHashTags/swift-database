
#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

public protocol SQLDataTypeProtocol: CustomStringConvertible, Sendable {
}

// MARK: Conformances





// MARK: Standard library

extension Bool: SQLDataTypeProtocol {}
extension String: SQLDataTypeProtocol {}
extension Substring: SQLDataTypeProtocol {}

extension Optional: SQLDataTypeProtocol, @retroactive CustomStringConvertible {
    public var description: String {
        "" // TODO: fix!
    }
}

extension Int: SQLDataTypeProtocol {}
extension Int8: SQLDataTypeProtocol {}
extension Int16: SQLDataTypeProtocol {}
extension Int32: SQLDataTypeProtocol {}
extension Int64: SQLDataTypeProtocol {}
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) extension Int128: SQLDataTypeProtocol {}

extension UInt: SQLDataTypeProtocol {}
extension UInt8: SQLDataTypeProtocol {}
extension UInt16: SQLDataTypeProtocol {}
extension UInt32: SQLDataTypeProtocol {}
extension UInt64: SQLDataTypeProtocol {}
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) extension UInt128: SQLDataTypeProtocol {}

// MARK: Foundation

#if canImport(FoundationEssentials) || canImport(Foundation)

extension Date: SQLDataTypeProtocol {}
extension UUID: SQLDataTypeProtocol {}

#endif