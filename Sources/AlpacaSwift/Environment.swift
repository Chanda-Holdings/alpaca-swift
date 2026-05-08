//
//  Environment.swift
//  
//
//  Created by Andrew Barba on 8/25/20.
//

import Foundation
import CryptoKit

public struct Environment: Hashable {
    public let api: String
    public let key: String
    public let secret: String
    public let access_token: String
    /// When true, requests sign with HTTP Basic instead of APCA headers.
    /// Set by `.broker(...)` (broker URL) and the broker-side data env.
    /// Defaults to false for backwards compat with existing factories.
    public var useBasicAuth: Bool = false
    /// Path segment inserted between `api` and the relative endpoint path
    /// for account-scoped requests. Set by `.broker(...)` to
    /// `"trading/accounts/{accountId}"`. Nil for non-broker envs and for
    /// the broker host's market-wide reference endpoints (calendar, clock,
    /// assets, options/contracts) which live at `api` directly.
    public var accountPathPrefix: String? = nil

   public var staticHashValue: String {
        let combined = "\(api)\(key)\(secret)\(access_token)\(useBasicAuth)\(accountPathPrefix ?? "")"
        let digest = SHA256.hash(data: combined.data(using: .utf8) ?? Data())
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }

    public static func ==(lhs: Environment, rhs: Environment) -> Bool {
         return lhs.api == rhs.api && lhs.key == rhs.key && lhs.secret == rhs.secret && lhs.access_token == rhs.access_token && lhs.useBasicAuth == rhs.useBasicAuth && lhs.accountPathPrefix == rhs.accountPathPrefix
     }
    
    public static func data(key: String, secret: String) -> Self {
        Environment(api: "https://data.alpaca.markets/v2", key: key, secret: secret, access_token: "")
    }
    
    public static func live(key: String, secret: String) -> Self {
        Environment(api: "https://api.alpaca.markets/v2", key: key, secret: secret, access_token: "")
    }
    
    public static func paper(key: String, secret: String) -> Self {
        Environment(api: "https://paper-api.alpaca.markets/v2", key: key, secret: secret, access_token: "")
    }
    
    public static func data(access_token: String) -> Self {
        Environment(api: "https://data.alpaca.markets/v2", key: "", secret: "", access_token: access_token)
    }
    
    public static func live(access_token: String) -> Self {
        Environment(api: "https://api.alpaca.markets/v2", key: "", secret: "",access_token: access_token)
    }
    
    public static func paper(access_token: String) -> Self {
        Environment(api: "https://paper-api.alpaca.markets/v2", key: "", secret: "",access_token: access_token)
    }

    /// Broker API sub-account. `api` is the broker host root (`/v1`); the
    /// per-account prefix lives in `accountPathPrefix` and is inserted by
    /// the request layer when `accountScoped == true`. This lets account-
    /// scoped endpoints (orders, positions, account, watchlists, portfolio
    /// history) keep their relative paths unchanged while market-wide
    /// reference endpoints (calendar, clock, assets, options/contracts)
    /// opt out via `accountScoped: false` and target the broker host root.
    public static func broker(key: String, secret: String, accountId: String, sandbox: Bool = true) -> Self {
        let host = sandbox ? "broker-api.sandbox.alpaca.markets" : "broker-api.alpaca.markets"
        return Environment(
            api: "https://\(host)/v1",
            key: key,
            secret: secret,
            access_token: "",
            useBasicAuth: true,
            accountPathPrefix: "trading/accounts/\(accountId)"
        )
    }

    /// Market data endpoint authenticated with broker credentials.
    /// Sandbox broker creds reach `data.sandbox.alpaca.markets`; live
    /// broker creds reach `data.alpaca.markets`. Both via HTTP Basic.
    public static func brokerData(key: String, secret: String, sandbox: Bool = false) -> Self {
        let host = sandbox ? "data.sandbox.alpaca.markets" : "data.alpaca.markets"
        return Environment(
            api: "https://\(host)/v2",
            key: key,
            secret: secret,
            access_token: "",
            useBasicAuth: true
        )
    }

    public func isPaper() -> Bool {
        // Broker-sandbox accounts are paper accounts by Alpaca convention.
        return self.api.contains("paper") || self.api.contains("broker-api.sandbox")
    }

    public func isBroker() -> Bool {
        return self.api.contains("broker-api")
    }

}
