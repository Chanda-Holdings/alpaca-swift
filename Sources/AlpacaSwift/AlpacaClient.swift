import Foundation

public struct AlpacaClient: AlpacaClientProtocol, Equatable {
    
    public static func ==(lhs: AlpacaClient, rhs: AlpacaClient) -> Bool {
        return lhs.environment == rhs.environment
    }
    
    public var environment: Environment
    
    public let data: AlpacaDataClient
    
    public let live: Environment
    
    public let paper: Environment
    
    public let timeoutInterval: TimeInterval
    
    public let canSwitch: Bool
    
    public init(_ environment: Environment, timeoutInterval: TimeInterval = 10, dataTimeoutInterval: TimeInterval = 10) {
        self.timeoutInterval = timeoutInterval
        if environment.access_token.isEmpty {
            self.canSwitch = false
            self.data = AlpacaDataClient(environment: Environment.data(key: environment.key, secret: environment.secret), timeoutInterval: dataTimeoutInterval)
            self.live = Environment.live(key: environment.key, secret: environment.secret)
            self.paper = Environment.paper(key: environment.key, secret: environment.secret)
        } else {
            self.canSwitch = true
            self.data = AlpacaDataClient(environment: Environment.data(access_token: environment.access_token), timeoutInterval: dataTimeoutInterval)
            self.live = Environment.live(access_token: environment.access_token)
            self.paper = Environment.paper(access_token: environment.access_token)
        }
        
        self.environment = environment.isPaper() ? self.paper : self.live
    }
    
}
