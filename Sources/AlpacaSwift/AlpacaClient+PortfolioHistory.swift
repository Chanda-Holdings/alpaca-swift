//
//  AlpacaClient+PortfolioHistory.swift
//  
//
//  Created by Andrew Barba on 8/15/20.
//

import Foundation

public struct PortfolioHistory: Codable {
    public enum Timeframe: String, Codable, CaseIterable {
        case oneMin = "1Min"
        case fiveMin = "5Min"
        case fifteenMin = "15Min"
        case oneHour = "1H"
        case oneDay = "1D"
    }
    
    public enum IntradayReporting: String, Codable, CaseIterable {
        case continuous
        case market_hours
        case extended_hours
    }
    
    public enum PnlReset: String, Codable, CaseIterable {
        case no_reset
        case per_day
    }
    
    
    public let timestamp: [Int]
    public let equity: [Double]
    public let profitLoss: [Double]
    public let profitLossPct: [Double]?
    public let baseValue: Double
    public let baseValueAsof: Date?
    public let timeframe: Timeframe
}

extension AlpacaClient {
    public func portfolioHistory(period: String? = nil, timeframe: PortfolioHistory.Timeframe? = nil, intraday_reporting: PortfolioHistory.IntradayReporting? = nil, pnl_reset: PortfolioHistory.PnlReset? = nil, start: Date? = nil, end: Date? = nil, dateEnd: Date? = nil, extendedHours: Bool? = nil) async throws -> PortfolioHistory {
        
        var dictionary: [String: String] = [:]

        // Assuming the types and default values
        // period is a String?
        let periodValue = period ?? "" // Default value if period is nil
        dictionary["period"] = periodValue

        // timeframe is an enum with rawValue of type String?
        if let timeframeValue = timeframe?.rawValue {
            dictionary["timeframe"] = timeframeValue
        }

        // intraday_reporting is an enum with rawValue of type String?
        if let intradayReportingValue = intraday_reporting?.rawValue {
            dictionary["intraday_reporting"] = intradayReportingValue
        }

        // start and end are Date?
        if let startDate = start {
            dictionary["start"] = Utils.iso8601DateFormatter.string(from: startDate)
        }
        if let endDate = end {
            dictionary["end"] = Utils.iso8601DateFormatter.string(from: endDate)
        }

        // pnl_reset is an enum with rawValue of type String?
        if let pnlResetValue = pnl_reset?.rawValue {
            dictionary["pnl_reset"] = pnlResetValue
        }

        // dateEnd is a Date?
        if let dateEndValue = dateEnd {
            dictionary["date_end"] = Utils.iso8601DateFormatter.string(from: dateEndValue)
        }

        // extendedHours is a Bool?
        if let extendedHoursValue = extendedHours {
            dictionary["extended_hours"] = String(extendedHoursValue)
        }
        
        return try await get("account/portfolio/history", searchParams: dictionary)
    }
}
