//
//  File.swift
//  
//
//  Created by Andrew Barba on 8/25/20.
//

import Foundation

public struct AlpacaDataClient: AlpacaClientProtocol {

    public let environment: Environment
    
    public let timeoutInterval: TimeInterval

    internal init(environment: Environment, timeoutInterval: TimeInterval) {
        self.environment = environment
        self.timeoutInterval = timeoutInterval
    }
}
