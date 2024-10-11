//
//  AlpacaClient+News.swift
//  Alpaca
//
//  Created by Yush Raj Kapoor on 4/10/24.
//

import Foundation
import UIKit

public struct News: Codable, Identifiable {
    public let id: Int
    public var headline: String
    public let author: String
    public let createdAt: Date
    public let updatedAt: Date
    public var summary: String
    public let content: String
    public let url: URL
    private var images: [[String: String]]
    public var thumb: URL? {
        if let thumb = images.first(where: { $0["size"] == "thumb" }), let url = thumb["url"] {
            return URL(string: url)
        }
        return nil
    }
    public var small: URL? {
        if let thumb = images.first(where: { $0["size"] == "small" }), let url = thumb["url"] {
            return URL(string: url)
        }
        return nil
    }
    public var large: URL? {
        if let thumb = images.first(where: { $0["size"] == "large" }), let url = thumb["url"] {
            return URL(string: url)
        }
        return nil
    }
    public let symbols: [String]
    public let source: String
    
    public func downloadThumbnail() async -> UIImage? {
        guard let thumb = thumb else { return nil }
        return await downloadImage(url: thumb)
    }
}

extension AlpacaDataClient {
    public func news(start: Date? = nil, end: Date? = nil, sort: SortDirection? = nil, symbols: [String]? = nil, limit: Int? = nil, includeContent: Bool? = nil, excludeContentless: Bool? = nil, pageToken: String? = nil) async throws -> [News] {
        return try await get("news", searchParams: [
            "start": start.map(Utils.iso8601DateFormatter.string),
            "end": end.map(Utils.iso8601DateFormatter.string),
            "sort": sort?.rawValue,
            "symbols": symbols?.joined(separator: ","),
            "limit": limit.map(String.init),
            "include_content": includeContent.map(String.init),
            "exclude_contentless": excludeContentless.map(String.init),
            "page_token": pageToken
        ])
    }
    
}
