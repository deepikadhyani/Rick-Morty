//
//  FetchEpisodesUseCase.swift
//  Rick&Morty
//
//  Created by Apple on 13/05/26.
//

import Foundation

/// Protocol defining the contract for executing episode fetching logic.
protocol FetchEpisodesUseCaseProtocol {
    func execute(from urls: [String]) async throws -> [Episode]
}

/// A Domain-level component responsible for coordinating the retrieval of episode data.
final class FetchEpisodesUseCase: FetchEpisodesUseCaseProtocol {
    
    private let repository: CharacterRepositoryProtocol
    
    // Injecting repository interface contract
    init(repository: CharacterRepositoryProtocol) {
        self.repository = repository
    }
    
    /// Coordinates fetching details for multiple episode URLs.
    func execute(from urls: [String]) async throws -> [Episode] {
        // Business Rule: Guard against empty datasets immediately
        // to prevent unnecessary processing or network cycles downstream.
        guard !urls.isEmpty else { return [] }
        
        // Fetch the raw data from the data provider layer
        let rawEpisodes = try await repository.fetchEpisodes(from: urls)
        
        // Sorted response sequentially by ID so they are presented in chronological appearance order
        let sortedEpisodes = rawEpisodes.sorted { $0.id < $1.id }
        
        
        return sortedEpisodes
    }
    
}
