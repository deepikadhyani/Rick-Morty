//
//  FetchCharactersUseCase.swift
//  Rick&Morty
//
//  Created by Apple on 13/05/26.
//

import Foundation

/// Protocol defining the contract for executing character fetching logic.
protocol FetchCharactersUseCaseProtocol {
    func execute(page: Int, name: String?) async throws -> [Character]
}

/// A Domain-level component responsible for processing inputs and fetching characters.
final class FetchCharactersUseCase: FetchCharactersUseCaseProtocol {
    
    // Initializer-based Dependency Injection.
    private let repository: CharacterRepositoryProtocol
    
    init(repository: CharacterRepositoryProtocol) {
        self.repository = repository
    }
    
    /// Executes the business logic for fetching characters.
    /// Sanitizes the search input string before passing it downstream.
    func execute(page: Int, name: String?) async throws -> [Character] {
        // Sanitize input: Trim whitespaces and newline characters
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If the query is just spaces, treat it as nil to fetch the default list instead of an empty query
        let queryName = trimmedName?.isEmpty == true ? nil : trimmedName
        return try await repository.fetchCharacters(page: page, name: queryName)
    }
}
