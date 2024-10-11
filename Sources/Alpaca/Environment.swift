//
//  File.swift
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
    
    var staticHashValue: String {
        let combined = "\(api)\(key)\(secret)\(access_token)"
        let digest = SHA256.hash(data: combined.data(using: .utf8) ?? Data())
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    public static func ==(lhs: Environment, rhs: Environment) -> Bool {
         return lhs.api == rhs.api && lhs.key == rhs.key && lhs.secret == rhs.secret && lhs.access_token == rhs.access_token
     }
    
    internal static func data(key: String, secret: String) -> Self {
        Environment(api: "https://data.alpaca.markets/v2", key: key, secret: secret, access_token: "")
    }
    
    public static func live(key: String, secret: String) -> Self {
        Environment(api: "https://api.alpaca.markets/v2", key: key, secret: secret, access_token: "")
    }
    
    internal static func paper(key: String, secret: String) -> Self {
        Environment(api: "https://paper-api.alpaca.markets/v2", key: key, secret: secret, access_token: "")
    }
    
    public static func data(access_token: String) -> Self {
        Environment(api: "https://data.alpaca.markets/v2", key: "", secret: "", access_token: access_token)
    }
    
    public static func live(access_token: String) -> Self {
        Environment(api: "https://api.alpaca.markets/v2", key: "", secret: "",access_token: access_token)
    }
    
    internal static func paper(access_token: String) -> Self {
        Environment(api: "https://paper-api.alpaca.markets/v2", key: "", secret: "",access_token: access_token)
    }
    
    func isPaper() -> Bool {
        return self.api.contains("paper")
    }
    
}
