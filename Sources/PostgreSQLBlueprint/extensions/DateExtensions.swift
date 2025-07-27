
#if canImport(FoundationEssentials) || canImport(Foundation)

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

import ModelUtilities

extension Date: PostgresDataDecodable {
    @inlinable
    static func tripleInt(_ value: some StringProtocol, separator: Character) -> (Int, Int, Int)? {
        let values = value.split(separator: separator)
        guard values.count == 3, let year = Int(values[0]), let month = Int(values[1]), let day = Int(values[2]) else { return nil }
        return (year, month, day)
    }
    @inlinable
    static func timestamp<T: StringProtocol>(
        _ value: T,
        precision: UInt8,
        withTimeZone: Bool
    ) -> DateComponents? {
        let values = value.split(separator: " ")
        guard values.count == 2, let (year, month, day) = tripleInt(values[0], separator: "-") else {
            return nil
        }
        var timezone:TimeZone? = .gmt
        let hour:Int
        let minute:Int
        let second:Int
        let nanosecond:Int
        if precision > 0 {
            let values = values[1].split(separator: ".")
            guard let v = tripleInt(values[0], separator: ":") else { return nil }
            hour = v.0
            minute = v.1
            second = v.2
            if values.count == 1 {
                nanosecond = 0
            } else {
                if withTimeZone {
                    let slug = values[1]
                    let values:[T.SubSequence]
                    let sign:Int
                    if slug.contains("+") {
                        sign = 1
                        values = slug.split(separator: "+")
                    } else {
                        sign = -1
                        values = slug.split(separator: "-")
                    }
                    guard values.count == 2, let n = Int(values[0]) else { return nil }
                    if let tzOffset = Int(values[1]) {
                        timezone = TimeZone(secondsFromGMT: sign * tzOffset * 3600)
                    }
                    nanosecond = n
                } else {
                    guard let n = Int(values[1]) else { return nil }
                    nanosecond = n
                }
            }
        } else {
            guard let v = tripleInt(values[1], separator: ":") else { return nil }
            hour = v.0
            minute = v.1
            second = v.2
            nanosecond = 0
        }
        return DateComponents(
            calendar: .current,
            timeZone: timezone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second,
            nanosecond: nanosecond
        )
    }

    @inlinable
    public static func postgresDecode(
        _ value: String,
        as type: PostgresDataType
    ) throws -> Date? {
        switch type {
        case .date:
            guard let (year, month, day) = tripleInt(value, separator: "-") else { return nil }
            return DateComponents(
                year: year,
                month: month,
                day: day,
                hour: 0,
                minute: 0,
                second: 0,
                nanosecond: 0
            ).date
        case .timestampNoTimeZone(let precision):
            return timestamp(value, precision: precision, withTimeZone: false)?.date
        case .timestampWithTimeZone(let precision):
            return timestamp(value, precision: precision, withTimeZone: true)?.date
        default:
            return nil
        }
    }
}

#endif