//
//  CharacterRepositoryProtocol.swift
//  Rick&Morty
//
//  Created by Apple on 13/05/26.
//

import Foundation

/// Defines the contract for fetching data. The Data layer will implement this protocol.
protocol CharacterRepositoryProtocol {
    
    /// Fetches a paginated list of characters, optionally filtered by a name query.
    ///
    /// - Parameters:
    ///   - page: The page number to fetch (1-indexed).
    ///   - name: An optional search filter string.
    /// - Returns: An array of domain-specific `Character` models.
    func fetchCharacters(page: Int, name: String?) async throws -> [Character]
    
    /// Fetches full data for a batch of specific episodes.
    ///
    /// - Parameter urls: An array of full API endpoint URLs for the required episodes.
    /// - Returns: An array of domain-specific `Episode` models.
    func fetchEpisodes(from urls: [String]) async throws -> [Episode]
}
