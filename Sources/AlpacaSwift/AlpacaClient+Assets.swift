//
//  AlpacaClient+Assets.swift
//  
//
//  Created by Andrew Barba on 8/15/20.
//

import Foundation

public struct Asset: Codable, Identifiable {
    public enum Class: String, Codable, CaseIterable {
        case usEquity = "us_equity"
        case crypto = "crypto"
        case cryptoPerp = "crypto_perp"
        case usOption = "us_option"
        
        public func display() -> String {
            return self.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    public enum Exchange: String, Codable, CaseIterable {
        case ascx = "ASCX"
        case amex = "AMEX"
        case arca = "ARCA"
        case bats = "BATS"
        case nyse = "NYSE"
        case nasdaq = "NASDAQ"
        case nyseArca = "NYSEARCA"
        case otc = "OTC"
        case crypto = "CRYPTO"
        case none = ""
    }

    public enum Status: String, Codable, CaseIterable {
        case active = "active"
        case inactive = "inactive"
    }
    
    public enum Attribute: String, Codable, CaseIterable {
        case ptpNoException = "ptp_no_exception"
        case ptpWithException = "ptp_with_exception"
        case ipo = "ipo"
        case fractionalEhEnabled = "fractional_eh_enabled"
        case hasOptions = "has_options"
        case optionsLateClose = "options_late_close"
        
    }

    public let id: UUID
    public let `class`: Class
    public let exchange: Exchange
    public let symbol: String
    public let name: String
    public let status: Status
    public let tradable: Bool
    public let marginable: Bool
    public let shortable: Bool
    public let easyToBorrow: Bool
    public let fractionable: Bool
    public let maintenanceMarginRequirement: Double
    public let attributes: [Attribute]?
}

public struct Contract: Codable, Identifiable {
    public enum Status: String, Codable, CaseIterable {
        case active = "active"
        case inactive = "inactive"
    }
    
    public enum ContractType: String, Codable, CaseIterable {
        case call = "call"
        case put = "put"
    }
    
    public enum Style: String, Codable, CaseIterable {
        case american = "american"
        case european = "european"
    }
    
    public let id: UUID
    public let symbol: String
    public let name: String
    public let status: Contract.Status
    public let tradable: Bool
    public let expirationDate: Date
    public let rootSymbol: String
    public let underlyingSymbol: String
    public let underlyingAssetId: String
    public let type: Contract.ContractType
    public let style: Contract.Style
    private let strikePrice: String
    public var strikePrixe: Double { Double(strikePrice)! }
    private let size: String
    public var contractSize: Int { Int(size)! }
    public let openInterest: String?
    public let openInterestDate: Date?
    public let closePrice: String?
    public let closePriceDate: Date?
    
    var breakeven: Double { strikePrixe + Double(closePrice ?? "0")! }
}

extension AlpacaClient {
    public func assets(status: Asset.Status? = nil, assetClass: Asset.Class? = nil, exchange: Asset.Exchange? = nil) async throws -> [Asset] {
        return try await get("assets", searchParams: ["status": status?.rawValue, "asset_class": assetClass?.rawValue, "exchange": exchange?.rawValue])
    }

    public func asset(id: String) async throws -> Asset {
        return try await get("assets/\(id)")
    }

    public func asset(id: UUID) async throws -> Asset {
        return try await get("assets/\(id.uuidString)")
    }

    public func asset(symbol: String) async throws -> Asset {
        return try await get("assets/\(symbol)")
    }
    
    
    public func getOptionContracts(symbols: [String]? = nil, status: Contract.Status? = Contract.Status.active, expirationDate: Date? = nil, expirationDateGTE: Date? = Date.now, expirationDateLTE: Date? = nil, rootSymbol: String? = nil, type: Contract.ContractType? = nil, style: Contract.Style? = nil, strikePriceGTE: Double? = nil, strikePriceLTE: Double? = nil, pageToken: String? = nil, limit: Int? = 10000) async throws -> [Contract] {
        let contracts:[Contract] = try await get("options/contracts", searchParams: [
            "underlying_symbols": symbols?.joined(separator: ","),
            "status": status?.rawValue,
            "expiration_date": expirationDate.map(Utils.iso8601DateOnlyFormatter.string),
            "expiration_date_gte": expirationDateGTE.map(Utils.iso8601DateOnlyFormatter.string),
            "expiration_date_lte": expirationDateLTE.map(Utils.iso8601DateOnlyFormatter.string),
            "root_symbol": rootSymbol,
            "type": type?.rawValue,
            "style": style?.rawValue,
            "strike_price_gte": strikePriceGTE?.absoluteString(),
            "strike_price_lte": strikePriceLTE?.absoluteString(),
            "limit": limit.map(String.init),
            "page_token": pageToken
        ])
        return contracts
    }
    
    public func getOptionContracts(symbol: String) async throws -> [Contract] {
        return try await getOptionContracts(symbols: [symbol])
    }
    
    public func getOptionContract(symbol_or_asset_id: String) async throws -> Contract {
        return try await get("options/contracts/\(symbol_or_asset_id)")
    }
    
    
}
