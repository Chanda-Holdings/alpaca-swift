//
//  Utils.swift
//  
//
//  Created by Andrew Barba on 8/15/20.
//

import Foundation

internal enum Utils {

    static let iso8601DateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Foundation.Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter
    }()

    static let iso8601DateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Foundation.Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let iso8601DateMillisecondsFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Foundation.Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS-ZZZZZ"
        return formatter
    }()
    
    static let iso8601DateMillisecondsTimeZoneFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    static let iso8601DateTimeZoneFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "Infinity",
            negativeInfinity: "-Infinity",
            nan: "NaN"
        )
        decoder.dateDecodingStrategy = .custom({ decoder in
            let container = try decoder.singleValueContainer()
            var value = try container.decode(String.self)
            value = String(value.split(separator: ".")[0])
            if let date = Self.iso8601DateFormatter.date(from: value) {
                return date
            }
            if let date = Self.iso8601DateMillisecondsFormatter.date(from: value) {
                return date
            }
            if let date = Self.iso8601DateOnlyFormatter.date(from: value) {
                return date
            }
            if let date = Self.iso8601DateMillisecondsTimeZoneFormatter.date(from: value) {
                return date
            }
            if let date = Self.iso8601DateTimeZoneFormatter.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(value)")
        })
        return decoder
    }()
}
