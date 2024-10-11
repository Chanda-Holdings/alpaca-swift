//
//  AlpacaDataClient+Snapshot.swift
//  Alpaca
//
//  Created by Yush Raj Kapoor on 2/7/24.
//

import Foundation

class Snapshot: Codable {
    
    public let dailyBar: Bar
    public let latestQuote: Quote
    public let minuteBar: Bar
    public let prevDailyBar: Bar
}


extension AlpacaDataClient {
    
    func snapshot(symbol: String, currency: String? = nil, feed: Quote.Feed? = nil) async throws -> Snapshot? {
        var feed = feed
        if feed == nil {
            feed = Quote.Feed(rawValue: UserDefaults.standard.string(forKey: "feed") ?? Quote.Feed.sip.rawValue)
        }
        do {
            let snapshot: Snapshot = try await get("stocks/\(symbol)/snapshot", searchParams: [
                "feed": feed?.rawValue,
                "currency": currency
            ])
            
            UserDefaults.standard.setValue(feed?.rawValue, forKey: "feed")
            return snapshot
        } catch {
            if feed == Quote.Feed.sip {
                feed = Quote.Feed.iex
            } else if feed == Quote.Feed.iex {
                feed = Quote.Feed.otc
            } else {
                return nil
            }

            let snapshot = try await snapshot(symbol: symbol, currency: currency, feed: feed)
            UserDefaults.standard.setValue(feed?.rawValue, forKey: "feed")
            return snapshot
        }
    }
    
    
    func snapshot(asset: Asset, currency: String? = nil) async throws -> Snapshot? {
        return try await snapshot(symbol: asset.symbol, currency: currency)
    }
}
