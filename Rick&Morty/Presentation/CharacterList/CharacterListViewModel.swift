//
//  CharacterListViewModel.swift
//  Rick&Morty
//
//  Created by Apple on 13/05/26.
//


import Foundation

enum CharacterListViewState {
    case loading
    case empty
    case error(String)
    case loaded([Character])
}

@MainActor
final class CharacterListViewModel: ObservableObject {
    
    // MARK: - Published
    
    @Published private(set) var state: CharacterListViewState = .loading
    @Published private(set) var isIncrementallyLoading = false
    
    @Published var searchQueryString: String = "" {
        didSet {
            debounceSearch()
        }
    }
    
    // MARK: - Dependencies
    
    private let fetchCharactersUseCase: FetchCharactersUseCaseProtocol
    
    // MARK: - Pagination State
    
    private var currentPage = 1
    private var canLoadMore = true
    private var loadedCharacters: [Character] = []
    
    // MARK: - Task Handles
    
    private var searchTask: Task<Void, Never>?
    private var paginationTask: Task<Void, Never>?
    
    // MARK: - Init
    
    init(fetchCharactersUseCase: FetchCharactersUseCaseProtocol) {
        self.fetchCharactersUseCase = fetchCharactersUseCase
    }
    
    // MARK: - Public Interface
    
    func loadInitialContent() async {
        guard loadedCharacters.isEmpty else { return }
        state = .loading
        await fetchNextPage()
    }
    
    func retry() async {
        await resetAndFetch()
    }
    
    /// Called by the list view as rows appear — triggers next page near the end.
    func handleItemAppearance(_ character: Character) {
        guard canLoadMore, paginationTask == nil else { return }
        
        let thresholdIndex = max(loadedCharacters.count - 5, 0)
        guard let index = loadedCharacters.firstIndex(where: { $0.id == character.id }),
              index >= thresholdIndex else { return }
        
        paginationTask = Task(priority: .userInitiated) { [weak self] in
            await self?.fetchNextPage()
            self?.paginationTask = nil
        }
    }
    
    // MARK: - Private
    
    private func debounceSearch() {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard let self, !Task.isCancelled else { return }
            await self.resetAndFetch()
        }
    }
    
    private func resetAndFetch() async {
        paginationTask?.cancel()
        paginationTask = nil
        
        currentPage = 1
        canLoadMore = true
        loadedCharacters = []
        state = .loading
        await fetchNextPage()
    }
    
    private func fetchNextPage() async {
        isIncrementallyLoading = true
        defer { isIncrementallyLoading = false }
        
        let queryAtCallTime = searchQueryString.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameFilter = queryAtCallTime.isEmpty ? nil : queryAtCallTime
        let pageToFetch = currentPage
        
        do {
            let batch = try await fetchCharactersUseCase.execute(
                page: pageToFetch,
                name: nameFilter
            )
            
            // Discard results if the search query changed while we were awaiting
            let currentQuery = searchQueryString.trimmingCharacters(in: .whitespacesAndNewlines)
            guard queryAtCallTime == currentQuery else { return }
            
            loadedCharacters.append(contentsOf: batch)
            currentPage += 1
            canLoadMore = !batch.isEmpty
            state = loadedCharacters.isEmpty ? .empty : .loaded(loadedCharacters)
            
        } catch {
            guard !Task.isCancelled else { return }
            
            if loadedCharacters.isEmpty {
                state = .error("Failed to connect. Please try again.")
            }
        }
    }
}
