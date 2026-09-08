//
//  Rick_MortyTests.swift
//  Rick&MortyTests
//
//  Created by Apple on 12/05/26.
//

import XCTest
@testable import Rick_Morty

// MARK: - Mock

/// A Mock repository.
/// Conforms to the real protocol so FetchCharactersUseCase
final class MockCharacterRepository: CharacterRepositoryProtocol {
    
    // set these before each test to control what the mock returns
    var stubbedCharacters: [Character] = []
    var stubbedError: Error? = nil
    
    // These record what arguments the UseCase actually passed in
    var capturedPage: Int?
    var capturedName: String?
    
    func fetchCharacters(page: Int, name: String?) async throws -> [Character] {
        // Record the inputs so we can assert on them later
        capturedPage = page
        capturedName = name
        
        // If we set an error, throw it — simulates a network failure
        if let error = stubbedError {
            throw error
        }
        
        return stubbedCharacters
    }
    
    func fetchEpisodes(from urls: [String]) async throws -> [Episode] {
        // Not needed for these tests — return empty
        return []
    }
}

// MARK: - Test Helper

/// A convenience factory.
/// Only sets the fields we care about; everything else gets a default.
extension Character {
    static func mock(
        id: Int = 1,
        name: String = "Rick Sanchez",
        status: CharacterStatus = .alive,
        species: String = "Human",
        gender: String = "Male",
        imageURLString: String = "https://example.com/image.jpg",
        originName: String = "Earth",
        locationName: String = "Earth",
        episodeURLs: [String] = []
    ) -> Character {
        Character(
            id: id,
            name: name,
            status: status,
            species: species,
            gender: gender,
            imageURLString: imageURLString,
            originName: originName,
            locationName: locationName,
            episodeURLs: episodeURLs
        )
    }
}

// MARK: - Suite 1: FetchCharactersUseCaseTests

final class FetchCharactersUseCaseTests: XCTestCase {
    
    var mockRepository: MockCharacterRepository!
    var sut: FetchCharactersUseCase!   // sut = System Under Test (the thing being tested)
    
    override func setUp() {
        super.setUp()
        mockRepository = MockCharacterRepository()
        sut = FetchCharactersUseCase(repository: mockRepository)
    }
    
    override func tearDown() {
        // Wipe them after each test so nothing bleeds between tests
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // ── Test 1 ──────────────────────────────────────────────────────────────
    // Does the UseCase pass the page number through to the repository correctly?
    func test_execute_passesCorrectPageToRepository() async throws {
        // Arrange
        mockRepository.stubbedCharacters = [.mock()]
        
        // Act
        _ = try await sut.execute(page: 3, name: nil)
        
        // Assert
        XCTAssertEqual(mockRepository.capturedPage, 3,
                       "UseCase should forward the page number to the repository unchanged")
    }
    
    // ── Test 2 ──────────────────────────────────────────────────────────────
    // A clean name string should pass through as-is
    func test_execute_passesNameToRepository() async throws {
        // Arrange
        mockRepository.stubbedCharacters = [.mock()]
        
        // Act
        _ = try await sut.execute(page: 1, name: "rick")
        
        // Assert
        XCTAssertEqual(mockRepository.capturedName, "rick",
                       "UseCase should forward a clean name string to the repository")
    }
    
    // ── Test 3 ──────────────────────────────────────────────────────────────
    // This is the sanitization logic — whitespace around the query should be stripped
    func test_execute_trimsWhitespaceFromName() async throws {
        // Arrange
        mockRepository.stubbedCharacters = [.mock()]
        
        // Act — notice the spaces around "rick"
        _ = try await sut.execute(page: 1, name: "  rick  ")
        
        // Assert — repository should receive the trimmed version
        XCTAssertEqual(mockRepository.capturedName, "rick",
                       "UseCase should trim whitespace from the name before calling the repository")
    }
    
    // ── Test 4 ──────────────────────────────────────────────────────────────
    // A name that is ONLY spaces should be treated as no filter at all (nil)
    func test_execute_treatsWhitespaceOnlyNameAsNil() async throws {
        // Arrange
        mockRepository.stubbedCharacters = [.mock()]
        
        // Act — spaces only
        _ = try await sut.execute(page: 1, name: "   ")
        
        // Assert — should become nil, not an empty or whitespace string
        XCTAssertNil(mockRepository.capturedName,
                     "A whitespace-only name should be converted to nil")
    }
    
    // ── Test 5 ──────────────────────────────────────────────────────────────
    // nil name should stay nil — don't accidentally convert it to something
    func test_execute_nilNamePassesThroughAsNil() async throws {
        // Arrange
        mockRepository.stubbedCharacters = [.mock()]
        
        // Act
        _ = try await sut.execute(page: 1, name: nil)
        
        // Assert
        XCTAssertNil(mockRepository.capturedName,
                     "nil name should be passed to the repository as nil")
    }
    
    // ── Test 6 ──────────────────────────────────────────────────────────────
    // The UseCase should return exactly what the repository gives it — no filtering, no mutation
    func test_execute_returnsRepositoryResults() async throws {
        // Arrange — two different characters
        let expectedCharacters = [
            Character.mock(id: 1, name: "Rick Sanchez"),
            Character.mock(id: 2, name: "Morty Smith")
        ]
        mockRepository.stubbedCharacters = expectedCharacters
        
        // Act
        let result = try await sut.execute(page: 1, name: nil)
        
        // Assert
        XCTAssertEqual(result, expectedCharacters,
                       "UseCase should return the repository's results unchanged")
    }
    
    // ── Test 7 ──────────────────────────────────────────────────────────────
    // If the repository throws, the UseCase should let that error bubble up — don't swallow it
    func test_execute_propagatesRepositoryError() async {
        // Arrange — tell the mock to throw a network error
        mockRepository.stubbedError = NetworkError.badResponse(statusCode: 500)
        
        // Act + Assert — we expect this to throw
        do {
            _ = try await sut.execute(page: 1, name: nil)
            XCTFail("Expected an error to be thrown but execute() returned successfully")
        } catch {
            // We got an error — that's the correct behaviour
            // Optionally verify it's the right kind of error
            guard case NetworkError.badResponse(let statusCode) = error else {
                XCTFail("Expected NetworkError.badResponse but got \(error)")
                return
            }
            XCTAssertEqual(statusCode, 500)
        }
    }
}


// MARK: - Mock URLProtocol

/// Intercepts URLSession requests at the protocol level.
/// Lets us return any data/response/error without hitting the real network.
final class MockURLProtocol: URLProtocol {
    
    // Set these before each test to control what the mock returns
    static var stubbedData: Data?
    static var stubbedResponse: HTTPURLResponse?
    static var stubbedError: Error?
    
    // URLProtocol requires this — return true to intercept ALL requests
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    // Required by URLProtocol — we don't need to modify the request
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    // called instead of a real network call
    override func startLoading() {
        if let error = MockURLProtocol.stubbedError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        // Send the stubbed HTTP response
        if let response = MockURLProtocol.stubbedResponse {
            client?.urlProtocol(self,
                                didReceive: response,
                                cacheStoragePolicy: .notAllowed)
        }
        
        // Send the stubbed data body
        if let data = MockURLProtocol.stubbedData {
            client?.urlProtocol(self, didLoad: data)
        }
        
        // Signal that loading is complete
        client?.urlProtocolDidFinishLoading(self)
    }
    
    // Required by URLProtocol — nothing to clean up
    override func stopLoading() {}
}

// MARK: - Suite 2: NetworkServiceTests

final class NetworkServiceTests: XCTestCase {
    
    var sut: NetworkService!
    var testURL: URL!
    
    override func setUp() {
        super.setUp()
        
        // Register our mock so URLSession uses it instead of the real network
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: config)
        
        sut = NetworkService(session: mockSession)
        testURL = URL(string: "https://rickandmortyapi.com/api/character")!
    }
    
    override func tearDown() {
        // Clear static properties so tests don't bleed into each other
        MockURLProtocol.stubbedData = nil
        MockURLProtocol.stubbedResponse = nil
        MockURLProtocol.stubbedError = nil
        sut = nil
        testURL = nil
        super.tearDown()
    }
    
    // Helper — builds a standard 200 OK HTTP response
    private func makeResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: testURL,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
    
    // ── Test 1 ──────────────────────────────────────────────────────────────
    // Happy path — valid JSON + 200 response should decode correctly
    func test_request_successfulResponse_decodesCorrectly() async throws {
        // Arrange
        let expectedDTO = EpisodeDTO(
            id: 1,
            name: "Pilot",
            air_date: "December 2, 2013",
            episode: "S01E01",
            characters: [],
            url: "https://rickandmortyapi.com/api/episode/1",
            created: "2017-11-10T12:56:33.798Z"
        )
        
        // Encoded back to JSON so MockURLProtocol can serve it
        let jsonData = try JSONEncoder().encode(expectedDTO)
        
        MockURLProtocol.stubbedData = jsonData
        MockURLProtocol.stubbedResponse = makeResponse(statusCode: 200)
        
        // Act
        let result: EpisodeDTO = try await sut.request(url: testURL)
        
        // Assert
        XCTAssertEqual(result.id, expectedDTO.id)
        XCTAssertEqual(result.name, expectedDTO.name)
        XCTAssertEqual(result.episode, expectedDTO.episode)
    }
    
    // ── Test 2 ──────────────────────────────────────────────────────────────
    // A 404 response should throw badResponse — not silently succeed
    func test_request_404Response_throwsBadResponse() async {
        // Arrange
        MockURLProtocol.stubbedData = Data()
        MockURLProtocol.stubbedResponse = makeResponse(statusCode: 404)
        
        // Act + Assert
        do {
            let _: EpisodeDTO = try await sut.request(url: testURL)
            XCTFail("Expected NetworkError.badResponse to be thrown")
        } catch {
            guard case NetworkError.badResponse(let statusCode) = error else {
                XCTFail("Expected NetworkError.badResponse but got \(error)")
                return
            }
            XCTAssertEqual(statusCode, 404)
        }
    }
    
    // ── Test 3 ──────────────────────────────────────────────────────────────
    // A 500 server error should also throw badResponse
    func test_request_500Response_throwsBadResponse() async {
        // Arrange
        MockURLProtocol.stubbedData = Data()
        MockURLProtocol.stubbedResponse = makeResponse(statusCode: 500)
        
        // Act + Assert
        do {
            let _: EpisodeDTO = try await sut.request(url: testURL)
            XCTFail("Expected NetworkError.badResponse to be thrown")
        } catch {
            guard case NetworkError.badResponse(let statusCode) = error else {
                XCTFail("Expected NetworkError.badResponse but got \(error)")
                return
            }
            XCTAssertEqual(statusCode, 500)
        }
    }
    
    // ── Test 4 ──────────────────────────────────────────────────────────────
    // Valid status but broken JSON should throw decodingError — not crash
    func test_request_malformedJSON_throwsDecodingError() async {
        // Arrange — garbage data that can't be decoded into any DTO
        MockURLProtocol.stubbedData = "{ totally: not valid json %%%".data(using: .utf8)
        MockURLProtocol.stubbedResponse = makeResponse(statusCode: 200)
        
        // Act + Assert
        do {
            let _: EpisodeDTO = try await sut.request(url: testURL)
            XCTFail("Expected NetworkError.decodingError to be thrown")
        } catch {
            guard case NetworkError.decodingError = error else {
                XCTFail("Expected NetworkError.decodingError but got \(error)")
                return
            }
            // Correct — malformed JSON should produce decodingError
        }
    }
    
    // ── Test 5 ──────────────────────────────────────────────────────────────
    // A 200 but completely empty body should also throw decodingError
    func test_request_emptyData_throwsDecodingError() async {
        // Arrange
        MockURLProtocol.stubbedData = Data() // empty body
        MockURLProtocol.stubbedResponse = makeResponse(statusCode: 200)
        
        // Act + Assert
        do {
            let _: EpisodeDTO = try await sut.request(url: testURL)
            XCTFail("Expected NetworkError.decodingError to be thrown")
        } catch {
            guard case NetworkError.decodingError = error else {
                XCTFail("Expected NetworkError.decodingError but got \(error)")
                return
            }
        }
    }
}


// MARK: - Mock

/// Fake UseCase we fully control — no real network, no real repository.
final class MockFetchCharactersUseCase: FetchCharactersUseCaseProtocol {
    
    // Control what gets returned
    var stubbedResult: [Character] = []
    var stubbedError: Error? = nil
    
    // Record what was passed in
    var capturedPage: Int?
    var capturedName: String?
    
    // Count how many times execute() was called
    var executeCallCount = 0
    
    func execute(page: Int, name: String?) async throws -> [Character] {
        capturedPage = page
        capturedName = name
        executeCallCount += 1
        
        if let error = stubbedError {
            throw error
        }
        
        return stubbedResult
    }
}

// MARK: - Suite 3: CharacterListViewModelTests

@MainActor
final class CharacterListViewModelTests: XCTestCase {
    
    var mockUseCase: MockFetchCharactersUseCase!
    var sut: CharacterListViewModel!
    
    override func setUp() {
        super.setUp()
        mockUseCase = MockFetchCharactersUseCase()
        sut = CharacterListViewModel(fetchCharactersUseCase: mockUseCase)
    }
    
    override func tearDown() {
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }
    
    // ── Test 1 ──────────────────────────────────────────────────────────────
    // Initial load with results should move state to .loaded
    func test_initialLoad_withResults_setsLoadedState() async {
        // Arrange
        mockUseCase.stubbedResult = [
            .mock(id: 1, name: "Rick Sanchez"),
            .mock(id: 2, name: "Morty Smith")
        ]
        
        // Act
        await sut.loadInitialContent()
        
        // Assert
        if case .loaded(let characters) = sut.state {
            XCTAssertEqual(characters.count, 2)
        } else {
            XCTFail("Expected .loaded state but got \(sut.state)")
        }
    }
    
    // ── Test 2 ──────────────────────────────────────────────────────────────
    // Initial load with empty results should move state to .empty
    func test_initialLoad_withNoResults_setsEmptyState() async {
        // Arrange — UseCase returns empty array
        mockUseCase.stubbedResult = []
        
        // Act
        await sut.loadInitialContent()
        
        // Assert
        if case .empty = sut.state {
            // Correct
        } else {
            XCTFail("Expected .empty state but got \(sut.state)")
        }
    }
    
    // ── Test 3 ──────────────────────────────────────────────────────────────
    // Initial load with a network failure should move state to .error
    func test_initialLoad_withError_setsErrorState() async {
        // Arrange
        mockUseCase.stubbedError = NetworkError.badResponse(statusCode: 500)
        
        // Act
        await sut.loadInitialContent()
        
        // Assert
        if case .error(let message) = sut.state {
            XCTAssertFalse(message.isEmpty, "Error message should not be empty")
        } else {
            XCTFail("Expected .error state but got \(sut.state)")
        }
    }
    
    // ── Test 4 ──────────────────────────────────────────────────────────────
    // Calling loadInitialContent() a second time should do nothing
    // — guards against unnecessary refetches when view reappears
    func test_initialLoad_calledTwice_doesNotRefetch() async {
        // Arrange
        mockUseCase.stubbedResult = [.mock()]
        
        // Act — call it twice
        await sut.loadInitialContent()
        await sut.loadInitialContent()
        
        // Assert — execute should only have been called once
        XCTAssertEqual(mockUseCase.executeCallCount, 1,
                       "loadInitialContent() should be a no-op if data is already loaded")
    }
    
    // ── Test 5 ──────────────────────────────────────────────────────────────
    // When the next page loads, its results should be appended — not replace — existing ones
    func test_pagination_appendsNextPageToExistingResults() async {
        // Arrange — first page returns 2 characters
        mockUseCase.stubbedResult = [
            .mock(id: 1, name: "Rick Sanchez"),
            .mock(id: 2, name: "Morty Smith")
        ]
        await sut.loadInitialContent()
        
        // Now stub page 2 with different characters
        mockUseCase.stubbedResult = [
            .mock(id: 3, name: "Summer Smith"),
            .mock(id: 4, name: "Beth Smith")
        ]
        
        // Trigger pagination by simulating the last character appearing on screen
        if case .loaded(let characters) = sut.state,
           let lastCharacter = characters.last {
            
            sut.handleItemAppearance(lastCharacter)
            
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        } else {
            XCTFail("Expected .loaded state after initial load")
            return
        }
        
        // Assert — all 4 characters should now be present
        if case .loaded(let allCharacters) = sut.state {
            XCTAssertEqual(allCharacters.count, 4,
                           "Pagination should append new characters to existing ones")
        } else {
            XCTFail("Expected .loaded state after pagination")
        }
    }
    
    // ── Test 6 ──────────────────────────────────────────────────────────────
    // When a page returns empty, canLoadMore should stop further pagination
    func test_pagination_emptyBatch_preventsfurtherLoading() async {
        // Arrange — first page has results
        mockUseCase.stubbedResult = [.mock(id: 1)]
        await sut.loadInitialContent()
        
        // Second call returns empty
        mockUseCase.stubbedResult = []
        
        if case .loaded(let characters) = sut.state,
           let lastCharacter = characters.last {
            
            sut.handleItemAppearance(lastCharacter)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        // this should NEVER be fetched
        mockUseCase.stubbedResult = [.mock(id: 99, name: "Should Not Appear")]
        
        // Try triggering pagination again
        if case .loaded(let characters) = sut.state,
           let lastCharacter = characters.last {
            sut.handleItemAppearance(lastCharacter)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        // Assert — only the original 1 character, pagination stopped
        if case .loaded(let allCharacters) = sut.state {
            XCTAssertEqual(allCharacters.count, 1,
                           "No further pages should load after an empty batch")
        } else if case .empty = sut.state {
            // Also acceptable — empty is correct when all pages exhausted
        } else {
            XCTFail("Unexpected state: \(sut.state)")
        }
    }
    
    // ── Test 7 ──────────────────────────────────────────────────────────────
    // Search should reset state and fetch fresh results
    func test_search_resetsAndFetchesFreshResults() async {
        // Arrange — load initial data first
        mockUseCase.stubbedResult = [.mock(id: 1, name: "Rick Sanchez")]
        await sut.loadInitialContent()
        
        // Now stub a search result
        mockUseCase.stubbedResult = [.mock(id: 2, name: "Morty Smith")]
        
        // Act — setting searchQueryString triggers debounceSearch()
        sut.searchQueryString = "Morty"
        
        // Wait for the 0.5s debounce + fetch to complete
        try? await Task.sleep(nanoseconds: 700_000_000) // 0.7 seconds
        
        // Assert — only search result should be present, not the original
        if case .loaded(let characters) = sut.state {
            XCTAssertEqual(characters.count, 1)
            XCTAssertEqual(characters.first?.name, "Morty Smith")
        } else {
            XCTFail("Expected .loaded state after search")
        }
    }
    
    // ── Test 8 ──────────────────────────────────────────────────────────────
    // Error during search should show error state only if no data was previously loaded
    func test_search_networkFailure_withNoExistingData_setsErrorState() async {
        // Arrange — no initial load, straight to a failing search
        mockUseCase.stubbedError = NetworkError.badResponse(statusCode: 500)
        
        // Act
        sut.searchQueryString = "anything"
        try? await Task.sleep(nanoseconds: 700_000_000)
        
        // Assert
        if case .error = sut.state {
            // Correct — no existing data so error should surface
        } else {
            XCTFail("Expected .error state but got \(sut.state)")
        }
    }
}
