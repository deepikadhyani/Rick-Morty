//
//  Rick_MortyApp.swift
//  Rick&Morty
//
//  Created by Apple on 12/05/26.
//

import SwiftUI

@main
struct RickAndMortyApp: App {
    
    // We instantiate the dependencies at the app's root lifecycle level
    private let characterListView: CharacterListView
    
    init() {
        // Initialize the low-level data infrastructure
        let networkService = NetworkService()
        
        let repository = CharacterRepository(
            networkService: networkService
        )
        
        // Initialize the domain layer use cases
        let fetchCharactersUseCase = FetchCharactersUseCase(
            repository: repository
        )
        let fetchEpisodesUseCase = FetchEpisodesUseCase(repository: repository)
        
        // Build List Presentation Layer
        let listViewModel = CharacterListViewModel(
            fetchCharactersUseCase: fetchCharactersUseCase
        )
        
        // Construct Root View with On-Demand Factory Closure
        self.characterListView = CharacterListView(
            viewModel: listViewModel,
            detailViewProvider: { character in
                let detailViewModel = CharacterDetailViewModel(
                    character: character,
                    fetchEpisodesUseCase: fetchEpisodesUseCase
                )
                return CharacterDetailView(viewModel: detailViewModel)
            }
        )    }
    
    var body: some Scene {
        WindowGroup {
            characterListView
        }
    }
}
