//
//  WKNetworkDispatcher.swift
//  
//
//  Created by Daniel Bernal on 15/11/20.
//


import Combine
import Foundation

public enum WKNetworkRequestError: LocalizedError, Equatable {
    case invalidRequest(_ body: String)
    case badRequest(_ body: String)
    case unauthorized(_ body: String)
    case forbidden(_ body: String)
    case notFound(_ body: String)
    case error4xx(_ code: Int, _ body: String)
    case serverError(_ body: String)
    case error5xx(_ code: Int, _ body: String)
    case decodingError(_ body: String)
    case urlSessionFailed(_ error: URLError, _ body: String)
    case unknownError(_ body: String)
}

public struct WKNetworkDispatcher {
        
    let urlSession: URLSession!
    
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    /// Dispatches an URLRequest and returns a publisher
    /// - Parameter request: URLRequest
    /// - Returns: A publisher with the provided decoded data or an error
    public func dispatch<ReturnType: Codable>(request: URLRequest) -> AnyPublisher<Data, WKNetworkRequestError> {
        
        return urlSession
            .dataTaskPublisher(for: request)
            .tryMap({ data, response in
                if let response = response as? HTTPURLResponse,
                 !(200...299).contains(response.statusCode) {
                    // print("ERROR: response response: \(response)")
                    let body = String(data: data, encoding: String.Encoding.utf8) ?? ""
                    // print("Failure Response: \(body )")
                    throw httpError(response.statusCode, body )
                }
                // print("response response: \(response)")

                let body = String(data: data, encoding: String.Encoding.utf8) ?? ""
                print("Response Body: \(body)")
                return data
            })
            // Not decode response, leave it to client to decide
            // .decode(type: ReturnType.self, decoder: JSONDecoder())
            .mapError { error in
               handleError(error, "")
            }
            .eraseToAnyPublisher()
    }
    
    
    /// Parses a HTTP StatusCode and returns a proper error
    /// - Parameter statusCode: HTTP status code
    /// - Returns: Mapped Error
    private func httpError(_ statusCode: Int, _ body: String) -> WKNetworkRequestError {
        switch statusCode {
            case 400: return .badRequest(body)
            case 401: return .unauthorized(body)
            case 403: return .forbidden(body)
            case 404: return .notFound(body)
            case 402, 405...499: return .error4xx(statusCode, body)
            case 500: return .serverError(body)
            case 501...599: return .error5xx(statusCode, body)
            default: return .unknownError(body)
        }
    }
    
    
    /// Parses URLSession Publisher errors and return proper ones
    /// - Parameter error: URLSession publisher error
    /// - Returns: Readable NWKNetworkRequestError
    private func handleError(_ error: Error, _ body: String) -> WKNetworkRequestError {
        switch error {
        case is Swift.DecodingError:
            return .decodingError(body)
        case let urlError as URLError:
            return .urlSessionFailed(urlError, body)
        case let error as WKNetworkRequestError:
            return error
        default:
            return .unknownError(body)
        }
    }
    
    private func debugMessage(_ message: String) {
        #if DEBUG
            print("--- WK Request \(message)")
        #endif
    }
    
}
