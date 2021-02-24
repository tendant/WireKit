//
//  WKAPIClient.swift
//  
//
//  Created by Daniel Bernal on 14/11/20.
//


import Foundation
import Combine

public struct WKAPIClient {
    
    public var baseURL: String!
    public var defaultHeaders: WKHTTPHeaders?
    public var networkDispatcher: WKNetworkDispatcher!
    
    public init(baseURL: String,
                defaultHeaders: WKHTTPHeaders? = nil,
                networkDispatcher: WKNetworkDispatcher = WKNetworkDispatcher()) {
        self.baseURL = baseURL
        self.networkDispatcher = networkDispatcher
    }
    
    /// Dispatches an WKRequest and returns a publisher
    /// - Parameter request: WKRequest to Dispatch
    /// - Returns: A publisher containing decoded data or an error
    public func dispatch<Request: WKRequest>(_ request: Request) -> AnyPublisher<Data, WKNetworkRequestError> {
        guard let urlRequest = request.asURLRequest(baseURL: baseURL, defaultHeaders: defaultHeaders) else {
            return Fail(outputType: Data.self, failure: WKNetworkRequestError.badRequest("")).eraseToAnyPublisher()
            
        }
        typealias RequestPublisher = AnyPublisher<Data, WKNetworkRequestError>
        let requestPublisher: RequestPublisher = networkDispatcher.dispatch(request: urlRequest)
        return requestPublisher.eraseToAnyPublisher()
    }
}
