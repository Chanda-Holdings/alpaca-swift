//
//  File.swift
//  
//
//  Created by Andrew Barba on 8/25/20.
//

import Foundation

public struct Bar: Codable {
    public enum Timeframe: String, CaseIterable {
        case oneMin = "1Min"
        case fiveMin = "5Min"
        case fifteenMin = "15Min"
        case oneDay = "1D"
    }

    private let t: Date
    public var timestamp: Date { t }

    private let o: Double
    public var open: Double { o }

    private let h: Double
    public var high: Double { h }

    private let l: Double
    public var low: Double { l }

    private let c: Double
    public var close: Double { c }

    private let v: Double
    public var volume: Double { v }
    
    private let n: Double
    public var tradeCount: Double { n }
    
    private let vw: Double
    public var volumeWeightedAveragePrice: Double { vw }
}

extension AlpacaDataClient {
    
    public func bars(_ timeframe: Bar.Timeframe, symbols: [String], feed: Quote.Feed? = nil, limit: Int? = nil, start: Date? = nil, end: Date? = nil) async throws -> [String: [Bar]] {
        var feed = feed
        if feed == nil {
            feed = Quote.Feed(rawValue: UserDefaults.standard.string(forKey: "bar_feed") ?? Quote.Feed.sip.rawValue)
        }
        do {
            let bars: [String: [Bar]] = try await get("stocks/bars", searchParams: [
                "symbols": symbols.joined(separator: ","),
                "timeframe": timeframe.rawValue,
                "feed": feed?.rawValue,
                "limit": limit.map(String.init),
                "start": start.map(Utils.iso8601DateFormatter.string),
                "end": end.map(Utils.iso8601DateFormatter.string),
                "adjustment": "all"
            ])
            
            UserDefaults.standard.setValue(feed?.rawValue, forKey: "bar_feed")
            return bars
        } catch {
            if feed == Quote.Feed.sip {
                feed = Quote.Feed.iex
            } else if feed == Quote.Feed.iex {
                feed = Quote.Feed.otc
            } else {
                return [:]
            }

            let bars = try await bars(timeframe, symbols: symbols, feed: feed, limit: limit, start: start, end: end)
            UserDefaults.standard.setValue(feed?.rawValue, forKey: "bar_feed")
            return bars
        }
    }

    public func bars(_ timeframe: Bar.Timeframe, symbol: String, limit: Int? = nil, start: Date? = nil, end: Date? = nil) async throws -> [Bar] {
        let res = try await bars(timeframe, symbols: [symbol], limit: limit, start: start, end: end)
        return res[symbol, default: []]
    }

    public func bars(_ timeframe: Bar.Timeframe, assets: [Asset], limit: Int? = nil, start: Date? = nil, end: Date? = nil) async throws -> [String: [Bar]] {
        return try await bars(timeframe, symbols: assets.map(\.symbol), limit: limit, start: start, end: end)
    }

    public func bars(_ timeframe: Bar.Timeframe, asset: Asset, limit: Int? = nil, start: Date? = nil, end: Date? = nil) async throws -> [Bar] {
        return try await bars(timeframe, symbol: asset.symbol, limit: limit, start: start, end: end)
    }
    
    public func latestBar(symbols: [String], feed: Quote.Feed? = nil) async throws -> [String: Bar] {
        var feed = feed
        if feed == nil {
            feed = Quote.Feed(rawValue: UserDefaults.standard.string(forKey: "feed") ?? Quote.Feed.sip.rawValue)
        }
        do {
            let bars: [String: Bar] = try await get("stocks/bars/latest", searchParams: [
                "symbols": symbols.joined(separator: ","),
                "feed": feed?.rawValue,
            ])
            
            UserDefaults.standard.setValue(feed?.rawValue, forKey: "feed")
            return bars
        } catch {
            if feed == Quote.Feed.sip {
                feed = Quote.Feed.iex
            } else if feed == Quote.Feed.iex {
                feed = Quote.Feed.otc
            } else {
                return [:]
            }

            let bars = try await latestBar(symbols: symbols, feed: feed)
            UserDefaults.standard.setValue(feed?.rawValue, forKey: "feed")
            return bars
        }
    }
    
    public func latestBar(symbol: String, feed: Quote.Feed? = nil) async throws -> [String: Bar] {
        return try await latestBar(symbols: [symbol])
    }
}
