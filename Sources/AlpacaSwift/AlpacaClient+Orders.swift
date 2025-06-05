//
//  AlpacaClient+Orders.swift
//
//
//  Created by Andrew Barba on 8/16/20.
//

import Foundation

public struct Order: Codable, Identifiable, Hashable, Equatable {
    public var hashValue: Int { get { return id.hashValue } }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func ==(left:Order, right:Order) -> Bool {
        return left.id == right.id
    }
    
    public enum Class: String, Codable, CaseIterable {
        case simple = "simple"
        case bracket = "bracket"
        case oco = "oco"
        case oto = "oto"
    }
    
    public enum Side: String, Codable, CaseIterable {
        case buy = "buy"
        case sell = "sell"
        
        public func display() -> String {
            return self.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
        
        public static func fromString(string: String) -> Side? {
            return Side(rawValue: string.lowercased().replacingOccurrences(of: " ", with: "_"))
        }
    }
    
    public enum PositionIntent: String, Codable, CaseIterable {
        case buyToOpen = "buy_to_open"
        case buyToClose = "buy_to_close"
        case sellToOpen = "sell_to_open"
        case sellToClose = "sell_to_close"
        
        public func display() -> String {
            return self.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
        
        public static func fromString(string: String) -> PositionIntent? {
            return PositionIntent(rawValue: string.lowercased().replacingOccurrences(of: " ", with: "_"))
        }
        
        public func side() -> Side {
            switch self {
            case .buyToOpen, .buyToClose:
                return Side.buy
            default:
                return Side.sell
            }
        }
    }
    
    public enum Status: String, Codable, CaseIterable {
        case new = "new"
        case partiallyFilled = "partially_filled"
        case filled = "filled"
        case doneForDay = "done_for_day"
        case canceled = "canceled"
        case expired = "expired"
        case replaced = "replaced"
        case pendingCancel = "pending_cancel"
        case pendingReplace = "pending_replace"
        case accepted = "accepted"
        case pendingNew = "pending_new"
        case acceptedForBidding = "accepted_for_bidding"
        case stopped = "stopped"
        case rejected = "rejected"
        case suspended = "suspended"
        case calculated = "calculated"
        case held = "held"
        
        public func display() -> String {
            return self.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
        
        public static func fromString(string: String) -> Status? {
            return Status(rawValue: string.lowercased().replacingOccurrences(of: " ", with: "_"))
        }
        
        // Used as query params
        public static let open = "open"
        public static let closed = "closed"
        public static let all = "all"
    }
    
    public enum OrderType: String, Codable, CaseIterable {
        case market = "market"
        case limit = "limit"
        case stop = "stop"
        case stopLimit = "stop_limit"
        case trailingStop = "trailing_stop"
        
        public func display() -> String {
            return self.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
        
        public static func optionDisplay() -> [String] {
            var disp: [String] = []
            for i in OrderType.allCases {
                if i == trailingStop { continue }
                disp.append(i.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
            }
            return disp
        }
        
        public static func fromString(string: String) -> OrderType? {
            return OrderType(rawValue: string.lowercased().replacingOccurrences(of: " ", with: "_"))
        }
    }
    
    public enum TimeInForce: String, Codable, CaseIterable {
        case day = "day"
        case gtc = "gtc"
        case opg = "opg"
        case cls = "cls"
        case ioc = "ioc"
        case fok = "fok"
        
        public func display() -> String {
            return TimeInForce.nameDict()[self]!.replacingOccurrences(of: "_", with: " ").capitalized
        }
        
        public static func nameDict() -> [TimeInForce: String] {
            return [TimeInForce.day: "Day", TimeInForce.gtc: "Good Until Canceled", TimeInForce.opg: "Market/Limit On Open", TimeInForce.cls: "Market/Limit On Close", TimeInForce.ioc: "Immediate Or Cancel", TimeInForce.fok: "Fill Or Kill"]
        }
        
        public static func reverseDictionary() -> [String: TimeInForce] {
            var reversedDictionary = [String: TimeInForce]()
            for (key, value) in TimeInForce.nameDict() {
                reversedDictionary[value] = key
            }
            return reversedDictionary
        }
        
        public static func fromString(string: String) -> TimeInForce? {
            if let tif = reverseDictionary()[string] {
                return tif
            }
            return nil
        }
    }
    
    public func isCancelable() -> Bool {
        return [Order.Status.new, Order.Status.accepted, Order.Status.pendingNew, Order.Status.partiallyFilled, Order.Status.acceptedForBidding, Order.Status.calculated, Order.Status.held].contains(self.status)
    }
    
    public func pnl(orderHistory: [Order]) -> Double? {
        if self.order_class == .bracket, let filledAvgPrice = self.filledAvgPrice?.value,
           let filledLeg = self.legs?.first(where: { $0.status == .filled && $0.filledAvgPrice?.value != nil }),
           let legPrice = filledLeg.filledAvgPrice?.value {
            return filledLeg.filledQty.value * legPrice - self.filledQty.value * filledAvgPrice
        }
        
        var lots: [(qty: Double, price: Double)] = []
        var position: Double = 0
        
        for order in orderHistory.lazy.filter({ $0.symbol == self.symbol }).sorted(by: { ($0.filledAt ?? .distantPast) < ($1.filledAt ?? .distantPast) }) {
            guard let price = order.filledAvgPrice?.value else { continue }
            let qty = order.filledQty.value
            let signed = order.side == .buy ? qty : -qty
            let isTarget = order.id == self.id
            
            if position == 0 || (position > 0) == (signed > 0) {
                if isTarget { return nil }
                lots.append((qty, price))
                position += signed
            } else {
                var remaining = abs(signed), pnl = 0.0
                let multiplier = signed > 0 ? 1.0 : -1.0
                var i = 0
                
                while remaining > 0 && i < lots.count {
                    let matched = min(remaining, lots[i].qty)
                    pnl += matched * multiplier * (lots[i].price - price)
                    remaining -= matched
                    position += multiplier * matched
                    
                    if lots[i].qty > matched {
                        lots[i].qty -= matched
                        i += 1
                    } else {
                        lots.remove(at: i)
                    }
                }
                
                if isTarget { return pnl }
                if remaining > 0 {
                    lots.insert((remaining, price), at: 0)
                    position += signed > 0 ? remaining : -remaining
                }
            }
        }
        
        return nil
    }
    
    public let id: UUID
    public let clientOrderId: String
    public let createdAt: Date
    public let updatedAt: Date?
    public let submittedAt: Date?
    public let filledAt: Date?
    public let expiredAt: Date?
    public let canceledAt: Date?
    public let failedAt: Date?
    public let replacedAt: Date?
    public let replacedBy: UUID?
    public let replaces: UUID?
    public let assetId: UUID
    public let symbol: String
    public let assetClass: Asset.Class
    public let qty: NumericString<Double>?
    public let filledQty: NumericString<Double>
    public let type: OrderType
    public let side: Side
    public let timeInForce: TimeInForce
    public let limitPrice: NumericString<Double>?
    public let stopPrice: NumericString<Double>?
    public let filledAvgPrice: NumericString<Double>?
    public let status: Status
    public let extendedHours: Bool
    public let legs: [Order]?
    public let order_class: Order.Class?
    public let trailPrice: NumericString<Double>?
    public let trailPercent: NumericString<Double>?
    public let notional: NumericString<Double>?
//    public let subtag: Any?
//    public let source: Any?
//    public let hwm: Any?
    public let positionIntent: PositionIntent?
    
}

extension AlpacaClient {
    public func orders(status: String? = nil, limit: Int? = nil, after: Date? = nil, until: Date? = nil, direction: SortDirection? = nil, nested: Bool? = nil, symbols:[String]? = nil, side: Order.Side? = nil) async throws -> [Order] {
        var searchParams:[String: String?] = [:]
        if let status = status {
            searchParams["status"] = status
        }
        if let limit = limit {
            searchParams["limit"] = String(limit)
        }
        if let after = after {
            searchParams["after"] = Utils.iso8601DateFormatter.string(from: after)
        }
        if let until = until {
            searchParams["until"] = Utils.iso8601DateFormatter.string(from: until)
        }
        if let direction = direction {
            searchParams["direction"] = direction.rawValue
        }
        if let nested = nested {
            searchParams["nested"] = String(nested)
        }
        if let symbols = symbols {
            searchParams["symbols"] = symbols.joined(separator: ",")
        }
        if let side = side {
            searchParams["side"] = side.rawValue
        }
       
        return try await get("orders", searchParams: searchParams)
    }
    
    public func order(id: UUID, nested: Bool? = nil) async throws -> Order {
        return try await get("orders/\(id)", searchParams: ["nested": nested.map(String.init)])
    }
    
    public func order(id: String, nested: Bool? = nil) async throws -> Order {
        return try await get("orders/\(id)", searchParams: ["nested": nested.map(String.init)])
    }
    
    public func createOrder(symbol: String, qty: Double, side: Order.Side, type: Order.OrderType, timeInForce: Order.TimeInForce, limitPrice: Double? = nil, stopPrice: Double? = nil, trailPrice: Double? = nil, trailPercent: Double? = nil, extendedHours: Bool = false, `class`: Order.Class? = nil, takeProfitLimitPrice: Double? = nil, stopLoss: Double? = nil, stopLimitPrice: Double? = nil, positionIntent: Order.PositionIntent? = nil) async throws -> Order {
        var body: [String: Any] = [
            "symbol": symbol,
            "qty": qty.absoluteString(),
            "side": side.rawValue,
            "type": type.rawValue,
            "time_in_force": timeInForce.rawValue,
            "extended_hours": extendedHours,
        ]
        
        if let limitPrice = limitPrice {
            body["limit_price"] = limitPrice.absoluteString()
        }
        if let stopPrice = stopPrice {
            body["stop_price"] = stopPrice.absoluteString()
        }
        if let trailPrice = trailPrice {
            body["trail_price"] = trailPrice.absoluteString()
        }
        if let trailPercent = trailPercent {
            body["trail_percent"] = trailPercent.absoluteString()
        }
        if let `class` = `class` {
            body["order_class"] = `class`.rawValue
        }
        if let takeProfitLimitPrice = takeProfitLimitPrice {
            body["take_profit"] = ["limit_price": takeProfitLimitPrice.absoluteString()]
        }
        var stopLossDict: [String: String] = [:]
        if let stopLoss = stopLoss {
            stopLossDict["stop_price"] = stopLoss.absoluteString()
        }
        if let stopLimitPrice = stopLimitPrice {
            stopLossDict["limit_price"] = stopLimitPrice.absoluteString()
        }
        body["stop_loss"] = stopLossDict.isEmpty ? nil : stopLossDict
        if let positionIntent = positionIntent {
            body["position_intent"] = positionIntent.rawValue
        }
        
        return try await post("orders", body: body)
    }
    
    public func cancelOrders() async throws -> [MultiResponse<Order>] {
        return try await delete("orders")
    }
    
    public func cancelOrder(id: String) async throws {
        let data: Data = try await delete("orders/\(id)")
    }
    
    public func cancelOrder(id: UUID) async throws {
        let data: Data = try await delete("orders/\(id.uuidString)")
    }
}


public extension Double {
    func absoluteString() -> String {
        return NSDecimalNumber(decimal: Decimal(self)).stringValue
    }
}
