//
//  AlpacaClient+Broker.swift
//
//  Broker-API-only endpoints. Use with `Environment.broker(...)`.
//

import Foundation

/// Minimal sub-account row returned by the Broker `GET /v1/accounts`
/// listing endpoint. Only the fields callers need to map an email →
/// sub-account UUID; expand as additional fields are required.
public struct BrokerAccountListing: Codable, Identifiable {
    public let id: UUID
    public let accountNumber: String?
    public let status: String?
    public let contact: Contact?

    public struct Contact: Codable {
        public let emailAddress: String?
    }
}

public enum BrokerError: Error {
    case requiresBrokerEnvironment
    case invalidURL
    case decodeFailed(Error)
}

extension AlpacaClient {

    /// Lists every sub-account under the firm. Use this once at app
    /// launch to build an `[email → accountId]` map; per-algo
    /// `Environment.broker(accountId:)` instances are then constructed
    /// from that map.
    ///
    /// `entities=contact` is required because the default response
    /// omits the contact sub-object — without it, the email isn't
    /// returned and callers can't disambiguate accounts.
    ///
    /// Targets the firm-level `/v1/accounts` endpoint by appending to
    /// `environment.api` (the broker host root, e.g. `https://<host>/v1`),
    /// bypassing the per-account `accountPathPrefix` used by relative-path
    /// endpoints.
    public func brokerListAccounts() async throws -> [BrokerAccountListing] {
        guard environment.isBroker() else {
            throw BrokerError.requiresBrokerEnvironment
        }
        guard var components = URLComponents(string: "\(environment.api)/accounts") else {
            throw BrokerError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "entities", value: "contact")]
        guard let url = components.url else { throw BrokerError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let token = "\(environment.key):\(environment.secret)"
        let encoded = Data(token.utf8).base64EncodedString()
        request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("alpaca-swift/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = timeoutInterval

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode([BrokerAccountListing].self, from: data)
        } catch {
            throw BrokerError.decodeFailed(error)
        }
    }
}
