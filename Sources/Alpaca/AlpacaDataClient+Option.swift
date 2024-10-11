//
//  AlpacaClient+Options.swift
//  Alpaca
//
//  Created by Yush Raj Kapoor on 3/29/24.
//

import Foundation

public struct OptionQuote: Codable {
    
    public enum Feed: String, Codable, CaseIterable {
        case opra = "opra"
        case indicative = "indicative"
    }
    
    private let t: Date
    public var timestamp: Date { t }
    
    private let bx: String
    public var bidExchange: String { bx }
    
    private let bp: Double
    public var bidPrice: Double { bp }
    
    private let bs: Int
    public var bidSize: Int { bs }
    
    private let ax: String
    public var askExchange: String { ax }
    
    private let ap: Double
    public var askPrice: Double { ap }
    
    private let `as`: Int
    public var askSize: Int { `as` }
    
    private let c: String
    public var conditionFlgs: String { c }
}



public class OptionSnapshot: Codable {
    public let latestTrade: Trade?
    public let latestQuote: OptionQuote
}

public struct Trade: Codable {
    private let t: Date
    public var timestamp: Date { t }

    private let x: String
    public var exchange: String { x }

    private let p: Double
    public var tradePrice: Double { p }

    private let s: Int
    public var tradeSize: Int { s }

    private let c: String
    public var tradeCondition: String { c }
}

extension AlpacaDataClient {
    
    public func historicalBars(symbols: [String], timeframe: Bar.Timeframe, start: Date? = nil, end: Date? = nil, limit: Int? = nil, pageToken: String? = nil, direction: SortDirection? = nil) async throws -> [String: [Bar]] {
        let bars: [String: [Bar]] = try await get("options/bars", searchParams: [
            "symbols": symbols.joined(separator: ","),
            "timeframe": timeframe.rawValue,
            "limit": limit.map(String.init),
            "start": start.map(Utils.iso8601DateFormatter.string),
            "end": end.map(Utils.iso8601DateFormatter.string),
            "page_token": pageToken,
            "sort": direction?.rawValue
        ])
        
        return bars
    }
    
    public func exchangeCodes() async throws -> [String: String] {
        return try await get("options/meta/exchanges")
    }
    
    public func latestQuotes(symbols: [String], feed: OptionQuote.Feed? = nil) async throws -> [Quote]  {
        var feed = feed
        if feed == nil {
            feed = OptionQuote.Feed(rawValue: UserDefaults.standard.string(forKey: "options_feed") ?? OptionQuote.Feed.opra.rawValue)
        }
        do {
            let quotes: [Quote] = try await get("options/quotes/latest", searchParams: [
                "symbols": symbols.joined(separator: ","),
                "feed": feed?.rawValue
            ])
            
            UserDefaults.standard.setValue(feed?.rawValue, forKey: "options_feed")
            return quotes
        } catch {
            if feed == OptionQuote.Feed.opra {
                feed = OptionQuote.Feed.indicative
            } else {
                return []
            }

            let quotes = try await latestQuotes(symbols: symbols, feed: feed)
            UserDefaults.standard.setValue(feed?.rawValue, forKey: "options_feed")
            return quotes
        }
    }
    
    public func latestTrades(symbols: [String], feed: OptionQuote.Feed? = nil) async throws -> [Trade]  {
        var feed = feed
        if feed == nil {
            feed = OptionQuote.Feed(rawValue: UserDefaults.standard.string(forKey: "options_feed") ?? OptionQuote.Feed.opra.rawValue)
        }
        do {
            let trades: [Trade] = try await get("options/trades/latest", searchParams: [
                "symbols": symbols.joined(separator: ","),
                "feed": feed?.rawValue
            ])
            
            UserDefaults.standard.setValue(feed?.rawValue, forKey: "options_feed")
            return trades
        } catch {
            if feed == OptionQuote.Feed.opra {
                feed = OptionQuote.Feed.indicative
            } else {
                return []
            }

            let trades = try await latestTrades(symbols: symbols, feed: feed)
            UserDefaults.standard.setValue(feed?.rawValue, forKey: "options_feed")
            return trades
        }
    }
    
    public func historical_trades(symbols: [String], timeframe: Bar.Timeframe, start: Date? = nil, end: Date? = nil, limit: Int? = nil, pageToken: String? = nil, direction: SortDirection? = nil) async throws -> [String: [Trade]] {
        let trades: [String: [Trade]] = try await get("options/trades", searchParams: [
            "symbols": symbols.joined(separator: ","),
            "timeframe": timeframe.rawValue,
            "limit": limit.map(String.init),
            "start": start.map(Utils.iso8601DateFormatter.string),
            "end": end.map(Utils.iso8601DateFormatter.string),
            "page_token": pageToken,
            "sort": direction?.rawValue
        ])
        
        return trades
    }
    
    public func optionSnapshots(symbols: [String], feed: OptionQuote.Feed? = nil) async throws -> [OptionSnapshot] {
        var feed = feed
        if feed == nil {
            feed = OptionQuote.Feed(rawValue: UserDefaults.standard.string(forKey: "options_feed") ?? OptionQuote.Feed.opra.rawValue)
        }
        do {
            let snapshots: [OptionSnapshot] = try await get("options/snapshots", searchParams: [
                "symbols": symbols.joined(separator: ","),
                "feed": feed?.rawValue
            ])
            
            UserDefaults.standard.setValue(feed?.rawValue, forKey: "options_feed")
            return snapshots
        } catch {
            if feed == OptionQuote.Feed.opra {
                feed = OptionQuote.Feed.indicative
            } else {
                return []
            }

            let snapshots = try await optionSnapshots(symbols: symbols, feed: feed)
            UserDefaults.standard.setValue(feed?.rawValue, forKey: "options_feed")
            return snapshots
        }
    }
    
    public func optionSnapshot(symbol: String) async throws -> OptionSnapshot? {
        if let snapshot = try await optionSnapshots(symbols: [symbol]).first {
            return snapshot
        }
        return nil
    }
    
    public func optionChain(symbol: String, feed: OptionQuote.Feed? = nil) async throws -> [String: OptionSnapshot] {
        var feed = feed
        if feed == nil {
            feed = OptionQuote.Feed(rawValue: UserDefaults.standard.string(forKey: "options_feed") ?? OptionQuote.Feed.opra.rawValue)
        }
        do {
            let snapshots: [String: OptionSnapshot] = try await get("options/snapshots/\(symbol)", searchParams: [
                "feed": feed?.rawValue
            ])
            
            UserDefaults.standard.setValue(feed?.rawValue, forKey: "options_feed")
            return snapshots
        } catch {
            if feed == OptionQuote.Feed.opra {
                feed = OptionQuote.Feed.indicative
            } else {
                return [:]
            }

            let snapshots = try await optionChain(symbol: symbol, feed: feed)
            UserDefaults.standard.setValue(feed?.rawValue, forKey: "options_feed")
            return snapshots
        }
    }
    
    
}
