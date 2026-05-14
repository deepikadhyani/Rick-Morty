//
//  CharacterRepository.swift
//  Rick&Morty
//
//  Created by Apple on 13/05/26.
//

import Foundation

/// Concrete implementation of the Character Repository.
/// Responsible for formatting URLs, passing requests to the network layer, and triggering domain mapping.
final class CharacterRepository: CharacterRepositoryProtocol {
    
    private let networkService: NetworkServiceProtocol
    private let baseURLString = "https://rickandmortyapi.com/api"
    
    // Inject the abstracted network contract
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    /// Fetches a paginated list of characters, appending an optional name filter query.
    func fetchCharacters(page: Int, name: String?) async throws -> [Character] {
        // Build base endpoint components
        var urlComponents = URLComponents(string: "\(baseURLString)/character")
        
        var queryItems = [URLQueryItem(name: "page", value: String(page))]
        if let name = name {
            queryItems.append(URLQueryItem(name: "name", value: name))
        }
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }
        do{
            // Execute request via network utility
            // Expected response type matches the outer JSON Envelope DTO
            let responseDTO: CharacterListResponseDTO = try await self.networkService.request(url: url)
            
            // Map the lower-level array of results into the domain models
            return responseDTO.results.map { $0.toDomain() }
            
        } catch {
            // Handle the Rick & Morty API's 404 behavior for empty search results
            // translate that "Error" into a successful "Empty List" for app logic.
            if case NetworkError.badResponse(let status) = error, status == 404 {
                return []
            }
            
            // If it's any other error (500, timeout, no internet), throw it normally
            throw error
        }
    }
    
    /// Fetches individual data profiles for multiple episodes in parallel.
    func fetchEpisodes(from urls: [String]) async throws -> [Episode] {
        // Business optimization rule:
        // Instead of triggering N separate individual network requests sequentially for N episode URLs,
        // we can extract the unique numeric IDs from the URLs and invoke the API's batch request feature.
        // e.g., turning ["https://.../episode/1", "https://.../episode/2"] -> "1,2"
        
        let episodeIDs = urls.compactMap { urlString -> String? in
            guard let lastComponent = urlString.split(separator: "/").last else { return nil }
            return String(lastComponent)
        }
        
        guard !episodeIDs.isEmpty else { return [] }
        let batchIDsString = episodeIDs.joined(separator: ",")
        
        // Build the combined batch endpoint URL
        guard let url = URL(string: "\(baseURLString)/episode/\(batchIDsString)") else {
            throw NetworkError.invalidURL
        }
        
        // Handle the API's polymorphic response schema:
        // If a character appeared in only one single episode, the API returns a standard single JSON object.
        // If they appeared in multiple episodes, it returns a JSON array of objects.
        if episodeIDs.count == 1 {
            let singleDTO: EpisodeDTO = try await networkService.request(url: url)
            return [singleDTO.toDomain()]
        } else {
            let listDTOs: [EpisodeDTO] = try await networkService.request(url: url)
            return listDTOs.map { $0.toDomain() }
        }
    }
    
}
