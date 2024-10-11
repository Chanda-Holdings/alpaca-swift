//
//  AlpacaClient+Error.swift
//  Alpaca
//
//  Created by Yush Raj Kapoor on 3/14/24.
//

import Foundation


public struct AlpacaError: Codable {
    public let message: String
    public let code: Int?
}

public enum AlpacaErrorType: Error {
    case error(AlpacaError)
}
