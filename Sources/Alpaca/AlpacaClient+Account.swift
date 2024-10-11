//
//  AlpacaClient+Account.swift
//  
//
//  Created by Andrew Barba on 8/15/20.
//

import Foundation

protocol AccountActivityProtocol {
    var id: String { get }
    // Include other common properties and methods here
}

public struct NonTradingAccountActivity: AccountActivityProtocol {
    public let id: String
    public let date: Date?
    public let netAmount: NumericString<Double>?
    public let symbol: String?
    public let qty: NumericString<Double>?
    public let perShareAmount: String?
}

public struct TradingAccountActivity: AccountActivityProtocol {
    public let id: String
    public let cumQty: NumericString<Double>?
    public let leavesQty: NumericString<Double>?
    public let side: Order.Side?
    public let symbol: String?
    public let activityType: AccountActivity.ActivityType?
    public let transactionTime: Date?
    public let type: AccountActivity.FillType?
    public let price: NumericString<Double>?
    public let qty: NumericString<Double>?
    public let orderId: String?
    public let status: Order.Status?
    
}

public class AccountActivity: Codable, Identifiable {
    public enum Category: String, Codable, CaseIterable {
        case tradingAccountActivity = "trade_activity"
        case nonTradingAccountActivity = "non_trade_activity"
    }
    public enum ActivityType: String, Codable, CaseIterable {
        case fill = "FILL"
        case trans = "TRANS"
        case misc = "MISC"
        case acatc = "ACATC"
        case acats = "ACATS"
        case cfee = "CFEE"
        case csd = "CSD"
        case csw = "CSW"
        case div = "DIV"
        case divcgl = "DIVCGL"
        case divcgs = "DIVCGS"
        case divfee = "DIVFEE"
        case divft = "DIVFT"
        case divnra = "DIVNRA"
        case divroc = "DIVROC"
        case divtw = "DIVTW"
        case divtxex = "DIVTXEX"
        case fee = "FEE"
        case int = "INT"
        case intnra = "INTNRA"
        case inttw = "INTTW"
        case jnl = "JNL"
        case jnlc = "JNLC"
        case jnls = "JNLS"
        case ma = "MA"
        case nc = "NC"
        case opasn = "OPASN"
        case opexc = "OPEXC"
        case opexp = "OPEXP"
        case optrd = "OPTRD"
        case ptc = "PTC"
        case ptr = "PTR"
        case reorg = "REORG"
        case sc = "SC"
        case sso = "SSO"
        case ssp = "SSP"
        
        
        func description() -> String {
            switch self {
            case .fill:
                return "Order fills (both partial and full fills)"
            case .trans:
                return "Cash transactions (both CSD and CSW)"
            case .misc:
                return "Miscellaneous or rarely used activity types (All types excpe those in TRANS, DIV, or FILL)"
            case .acatc:
                return "Automated Customer Account Transfer Cash"
            case .acats:
                return "Automated Customer Account Transfer Securities"
            case .cfee:
                return "Crypto fee"
            case .csd:
                return "Cash deposit (+)"
            case .csw:
                return "Cash withdrawal (-)"
            case .div:
                return "Dividends"
            case .divcgl:
                return "Dividend (capital gain long term)"
            case .divcgs:
                return "Dividend (capital gain short term)"
            case .divfee:
                return "Dividend fee"
            case .divft:
                return "Dividend adjusted (Foreign Tax Witheld)"
            case .divnra:
                return "Dividend adjusted (NRA Witheld)"
            case .divroc:
                return "Dividend return of capital"
            case .divtw:
                return "Dividend adjusted (Tefra Witheld)"
            case .divtxex:
                return "Dividend (tax exempt)"
            case .fee:
                return "Fee denominated in USD"
            case .int:
                return "Interest (credit/margin)"
            case .intnra:
                return "Interest adjusted (NRA witheld)"
            case .inttw:
                return "Interest adjusted (Tefra witheld)"
            case .jnl:
                return "Journal entry"
            case .jnlc:
                return "Journal entry (cash)"
            case .jnls:
                return "Journal entry (stock)"
            case .ma:
                return "Merger/Acquisition"
            case .nc:
                return "Name change"
            case .opasn:
                return  "Option assignment"
            case .opexc:
                return "Option exercise"
            case .opexp:
                return "Option expiration"
            case .optrd:
                return "Option trade"
            case .ptc:
                return "Pass Thru Charge"
            case .ptr:
                return "Pass Thru Rebate"
            case .reorg:
                return "Reorg CA"
            case .sc:
                return "Symbol change"
            case .sso:
                return "Stock spinoff"
            case .ssp:
                return "Stock split"
            }
        }
    }
    
    public enum FillType: String, Codable, CaseIterable {
        case fill = "fill"
        case partialFill = "partial_fill"
    }
    
}

public struct Account: Codable, Identifiable {
    
    public enum Status: String, Codable, CaseIterable {
        case onboarding = "ONBOARDING"
        case submissionFailed = "SUBMISSION_FAILED"
        case submitted = "SUBMITTED"
        case accountUpdated = "ACCOUNT_UPDATED"
        case approvalPending = "APPROVAL_PENDING"
        case active = "ACTIVE"
        case rejected = "REJECTED"
    }

    public let id: UUID
    public let accountNumber: String
    public let currency: String
    public let cash: NumericString<Double>
    public let status: Status
    public let patternDayTrader: Bool
    public let tradeSuspendedByUser: Bool
    public let tradingBlocked: Bool
    public let transfersBlocked: Bool
    public let accountBlocked: Bool
    public let createdAt: Date
    public let shortingEnabled: Bool
    public let longMarketValue: NumericString<Double>
    public let shortMarketValue: NumericString<Double>
    public let equity: NumericString<Double>
    public let lastEquity: NumericString<Double>
    public let multiplier: NumericString<Double>
    public let buyingPower: NumericString<Double>
    public let initialMargin: NumericString<Double>
    public let maintenanceMargin: NumericString<Double>
    public let sma: NumericString<Double>
    public let daytradeCount: Int
    public let lastMaintenanceMargin: NumericString<Double>
    public let daytradingBuyingPower: NumericString<Double>
    public let regtBuyingPower: NumericString<Double>
}

extension AlpacaClient {
    public func account() async throws -> Account {
        return try await get("account")
    }
    
    public func getAccountActivity(activityTypes: [AccountActivity.ActivityType]) async throws -> [AccountActivity] {
        return try await get("account/activities", searchParams: [
            "activity_types": activityTypes.map({ $0.rawValue }).joined(separator: ",")
        ])
    }
    
    public func getAccountActivity(activityType: AccountActivity.ActivityType, date: Date? = nil, until: Date? = nil, after: Date? = nil, direction: SortDirection? = nil, pageSize: Int? = nil, pageToken: String? = nil, category: AccountActivity.Category? = nil) async throws -> [AccountActivity] {
        return try await get("account/activities/\(activityType.rawValue)", searchParams: [
            "date": date.map(Utils.iso8601DateFormatter.string),
            "until": until.map(Utils.iso8601DateFormatter.string),
            "after": after.map(Utils.iso8601DateFormatter.string),
            "direction": direction?.rawValue,
            "page_size": pageSize.map(String.init),
            "page_token": pageToken,
            "category": category?.rawValue
        ])
    }
}
