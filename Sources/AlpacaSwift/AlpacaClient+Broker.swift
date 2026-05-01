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
    /// Builds its own URL (rooted at `/v1/accounts`, not the per-account
    /// `/v1/trading/accounts/{aid}` path baked into the broker
    /// environment) so the existing relative-path endpoint extensions
    /// don't need any changes to handle this firm-level call.
    public func brokerListAccounts() async throws -> [BrokerAccountListing] {
        guard environment.isBroker() else {
            throw BrokerError.requiresBrokerEnvironment
        }
        // environment.api is "https://<host>/v1/trading/accounts/<aid>";
        // strip the per-account suffix to land at "/v1/accounts".
        guard
            let baseURL = URL(string: environment.api),
            var components = URLComponents(
                url: baseURL.deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .appendingPathComponent("accounts"),
                resolvingAgainstBaseURL: false
            )
        else {
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
