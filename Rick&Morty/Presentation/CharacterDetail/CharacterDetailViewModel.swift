//
//  CharacterDetailViewModel.swift
//  Rick&Morty
//
//  Created by Apple on 13/05/26.
//

import Foundation

@MainActor
final class CharacterDetailViewModel: ObservableObject {
    
    // UI State Machine representation
    enum EpisodeState {
        case idle
        case loading
        case loaded([Episode])
        case error(String)
    }
    
    // MARK: - Properties
    @Published private(set) var state: EpisodeState = .idle
    
    // The parent entity domain model
    let character: Character
    
    // Dependencies injected via protocols
    private let fetchEpisodesUseCase: FetchEpisodesUseCaseProtocol
    
    // MARK: - Initializer
    init(character: Character, fetchEpisodesUseCase: FetchEpisodesUseCaseProtocol) {
        self.character = character
        self.fetchEpisodesUseCase = fetchEpisodesUseCase
    }
    
    // MARK: - Intent Execution
    /// Parses the character's episode URLs and fetches their full records concurrently.
    func loadEpisodes() async {
        
        guard !character.episodeURLs.isEmpty else {
            state = .loaded([])
            return
        }
        
        state = .loading
        
        do {
            // Business rule orchestration delegating to the UseCase layer
            let episodes = try await fetchEpisodesUseCase.execute(from: character.episodeURLs)
            
            state = .loaded(episodes)
            
        } catch {
            // Structured error interpretation
            state = .error("Failed to load episode details. Please try again.")
        }
    }
}
