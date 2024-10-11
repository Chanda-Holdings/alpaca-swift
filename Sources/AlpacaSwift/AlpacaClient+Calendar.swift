//
//  AlpacaClient+Calendar.swift
//  
//
//  Created by Andrew Barba on 8/15/20.
//

import Foundation

public struct Calendar: Codable {
    public let date: Date
    public let open: String
    public let close: String
    public let settlementDate: Date
}

extension AlpacaClient {
    public func calendar(start: Date? = nil, end: Date? = nil) async throws -> [Date] {
        let calendar: [Calendar] = try await calendar(start: start, end: end)
        let timeZoneOffset = TimeZone(identifier: "America/New_York")!.secondsFromGMT() - TimeZone(identifier: "GMT")!.secondsFromGMT()
        let dates = calendar.map({ $0.date.addingTimeInterval(Double(timeZoneOffset / 3600)).addingTimeInterval($0.open.timeIntervalFromString()) })
        return dates
    }
    
    public func calendar(start: Date? = nil, end: Date? = nil) async throws -> [Calendar] {
        return try await get("calendar", searchParams: ["start": start.map(Utils.iso8601DateFormatter.string), "end": end.map(Utils.iso8601DateFormatter.string)])
    }
}


public extension String {
    func timeIntervalFromString() -> TimeInterval {
        let components = self.split(separator: ":")
        guard components.count == 2,
              let hours = Int(components[0]),
              let minutes = Int(components[1]) else {
            return 0.0
        }
        
        let totalSeconds = TimeInterval(hours * 3600 + minutes * 60)
        return totalSeconds
    }
}
