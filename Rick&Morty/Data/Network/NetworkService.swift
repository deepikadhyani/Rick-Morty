//
//  NetworkService.swift
//  Rick&Morty
//
//  Created by Apple on 13/05/26.
//

import Foundation

/// Custom data layer errors that categorize typical REST API network failures.
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case badResponse(statusCode: Int)
    case decodingError
    case serverError(String)
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The endpoint URL generated was invalid."
        case .badResponse: return "The server returned an invalid response."
        case .decodingError: return "Failed to process and map the payload data from the server."
        case .rateLimited: return "The server rate-limited requests."
        case .serverError(let message): return message
        }
    }
}

/// The abstraction contract hiding URLSession.
/// Enforcing this protocol guarantees that the entire network layout is mockable.
protocol NetworkServiceProtocol {
    func request<T: Decodable>(url: URL) async throws -> T
}

/// Concrete network manager using native Swift Concurrency async/await syntax.
final class NetworkService: NetworkServiceProtocol {
    
    private let session: URLSession
    
    // Initializer-based Dependency Injection.
    // Defaults to .shared for runtime execution, but allows us to pass a Mock Configuration during tests.
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Perfroms a concurrent network call and decodes JSON response data natively.
    func request<T: Decodable>(url: URL) async throws -> T {
        // Fetch raw data concurrently using async native APIs
        let (data, response) = try await session.data(from: url)
        
        // Inside your NetworkService request method
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.badResponse(statusCode: 0)
        }
        
        // Check if status is outside the 200-299 range
        if !(200...299).contains(httpResponse.statusCode) {
            // Throw the error with the status code
            throw NetworkError.badResponse(statusCode: httpResponse.statusCode)
        }
        
        // Decode the data back to target Decodable DTO
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    
}

