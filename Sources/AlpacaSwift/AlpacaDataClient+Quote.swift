//
//  AlpacaDataClient+Quote.swift
//  Alpaca
//
//  Created by Yush Raj Kapoor on 2/7/24.
//

import Foundation


public struct Quote: Codable {
    public enum Exchange: String, Codable, CaseIterable {
        case amex = "AMEX"
        case arca = "ARCA"
        case bats = "BATS"
        case nyse = "NYSE"
        case nasdaq = "NASDAQ"
        case nyseArca = "NYSEARCA"
        case otc = "OTC"
        case crypto = "CRYPTO"
    }
    
    public enum Feed: String, Codable, CaseIterable {
        case sip = "sip"
        case iex = "iex"
        case otc = "otc"
    }
    
    public enum Sort: String, Codable, CaseIterable {
        case asc = "asc"
        case desc = "desc"
    }
    
    init(timestamp: Date, price: Double) {
        self.t = timestamp
        self.bx = ""
        self.bp = price
        self.bs = 0
        self.ax = ""
        self.ap = price
        self.as = 0
        self.c = []
        self.z = ""
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
    
    private let c: [String]
    public var conditionFlgs: [String] { c }
    
    private let z: String
    public var tape: String { z }
    
    
}

extension AlpacaDataClient {
    
    public func quotes(symbol: String, feed: Quote.Feed? = nil, currency: String? = nil, start: Date? = nil, end: Date? = nil, limit: Int? = nil, asof: Date? = nil, sort: Quote.Sort? = nil) async throws -> [Quote] {
        var feed = feed
        if feed == nil {
            feed = Quote.Feed(rawValue: UserDefaults.standard.string(forKey: "feed") ?? Quote.Feed.sip.rawValue)
        }
        do {
            let quotes: [Quote] = try await get("stocks/\(symbol)/quotes", searchParams: [
                "feed": feed?.rawValue,
                "currency": currency,
                "start": start.map(Utils.iso8601DateFormatter.string),
                "end": end.map(Utils.iso8601DateFormatter.string),
                "limit": limit.map(String.init),
                "asof": asof.map(Utils.iso8601DateFormatter.string),
                "sort": sort?.rawValue
            ])
            UserDefaults.standard.setValue(feed?.rawValue, forKey: "feed")
            return quotes
        } catch {
            print(error)
            if feed == Quote.Feed.sip {
                feed = Quote.Feed.iex
            } else if feed == Quote.Feed.iex {
                feed = Quote.Feed.otc
            } else {
                throw error
            }
            let quotes = try await quotes(symbol: symbol, feed: feed, currency: currency, start: start, end: end, limit: limit, asof: asof, sort: sort)
            UserDefaults.standard.setValue(feed?.rawValue, forKey: "feed")
            return quotes
        }
    }
    
    public func quotes(asset: Asset, currency: String? = nil, start: Date? = nil, end: Date? = nil, limit: Int? = nil, asof: Date? = nil, sort: Quote.Sort? = nil) async throws -> [Quote] {
        return try await quotes(symbol: asset.symbol, currency: currency, start: start, end: end, limit: limit, asof: asof, sort: sort)
    }
    
    public func quote(symbol: String, feed: Quote.Feed? = nil, currency: String? = nil) async throws -> Quote {
        var feed = feed
        if feed == nil {
            feed = Quote.Feed(rawValue: UserDefaults.standard.string(forKey: "feed") ?? Quote.Feed.sip.rawValue)
        }
        do {
            let quote: Quote =  try await get("stocks/\(symbol)/quotes/latest", searchParams: [
                "feed": feed?.rawValue,
                "currency": currency
            ])
            UserDefaults.standard.setValue(feed?.rawValue, forKey: "feed")
            return quote
        } catch {
            print(error)
            if feed == Quote.Feed.sip {
                feed = Quote.Feed.iex
            } else if feed == Quote.Feed.iex {
                feed = Quote.Feed.otc
            } else {
                throw error
            }
            let quotes = try await quote(symbol: symbol, feed: feed, currency: currency)
            UserDefaults.standard.setValue(feed?.rawValue, forKey: "feed")
            return quotes
        }
    }
    
    
}
