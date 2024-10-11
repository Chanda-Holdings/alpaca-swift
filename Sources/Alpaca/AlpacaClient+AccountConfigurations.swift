//
//  AlpacaClient+AccountConfiguration.swift
//  
//
//  Created by Andrew Barba on 8/15/20.
//

import Foundation

public struct AccountConfigurations: Codable {
    public enum DayTradeBuyingPowerCheck: String, Codable, CaseIterable {
        case both = "both"
        case entry = "entry"
        case exit = "exit"
    }
    
    public enum PatternDayTraderCheck: String, Codable, CaseIterable {
        case both = "both"
        case entry = "entry"
        case exit = "exit"
    }

    public enum TradeConfirmEmail: String, Codable, CaseIterable {
        case all = "all"
        case none = "none"
    }
    
    public enum MarginMultipler: String, Codable, CaseIterable {
        case oneX = "1"
        case twoX = "2"
        case fourX = "4"
    }
    
    public enum OptionsTradingLevel: Int, Codable, CaseIterable {
        case disabled = 0
        case level1 = 1
        case level2 = 2
        
        func description() -> String {
            switch self {
            case .disabled:
                return "Disabled"
            case .level1:
                return "Covered Call/Cash-Secured Put"
            case .level2:
                return "Covered Call/Cash-Secured Put and Long Call/Put"
            }
        }
        
        func display() -> String {
            switch self {
            case .disabled:
                return "Disabled"
            case .level1:
                return "Level 1"
            case .level2:
                return "Level 2"
            }
        }
    }

    public var dtbpCheck: DayTradeBuyingPowerCheck
    public var noShorting: Bool
    public var suspendTrade: Bool
    public var tradeConfirmEmail: TradeConfirmEmail
    public var fractionalTrading: Bool
    public var maxMarginMultiplier: MarginMultipler
    public var maxOptionsTradingLevel: OptionsTradingLevel?
    public var pdtCheck: PatternDayTraderCheck
    public var ptpNoExceptionEntry: Bool
}

extension AlpacaClient {
    public func accountConfigurations() async throws -> AccountConfigurations {
        return try await get("account/configurations")
    }

    public func saveAccountConfigurations(_ configurations: AccountConfigurations) async throws -> AccountConfigurations {
        return try await patch("account/configurations", body: configurations)
    }

    public func saveAccountConfigurations(dtbpCheck: AccountConfigurations.DayTradeBuyingPowerCheck? = nil, tradeConfirmEmail: AccountConfigurations.TradeConfirmEmail? = nil, suspendTrade: Bool? = nil, noShorting: Bool? = nil, fractionalTrading: Bool? = nil, maxMarginMultiplier: AccountConfigurations.MarginMultipler? = nil, maxOptionsTradingLevel: AccountConfigurations.OptionsTradingLevel? = nil, pdtCheck: AccountConfigurations.PatternDayTraderCheck? = nil, ptpNoExceptionEntry: Bool? = nil) async throws -> AccountConfigurations {
        return try await patch("account/configurations", body: [
            "dtbp_check": dtbpCheck?.rawValue,
            "trade_confirm_email": tradeConfirmEmail?.rawValue,
            "suspend_trade": suspendTrade,
            "no_shorting": noShorting,
            "fractional_trading": fractionalTrading,
            "max_margin_multiplier": maxMarginMultiplier?.rawValue,
            "max_options_trading_level": maxOptionsTradingLevel?.rawValue,
            "pdt_check": pdtCheck?.rawValue,
            "ptp_no_exception_entry": ptpNoExceptionEntry
        ])
    }
}
