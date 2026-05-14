//
//  CharacterDTOs.swift
//  Rick&Morty
//
//  Created by Apple on 13/05/26.
//

import Foundation

/// The top-level response envelope returned when fetching the character list.
struct CharacterListResponseDTO: Decodable {
    let info: PageInfoDTO
    let results: [CharacterDTO]
}

/// Metadata containing pagination info.
struct PageInfoDTO: Decodable {
    let count: Int
    let pages: Int
    let next: String?
    let prev: String?
}

/// The individual character model matching the API schema exactly.
struct CharacterDTO: Decodable {
    let id: Int
    let name: String
    let status: String
    let species: String
    let type: String
    let gender: String
    let origin: LocationReferenceDTO
    let location: LocationReferenceDTO
    let image: String
    let episode: [String]
    let url: String
    let created: String
}

/// Nested structure representing origins and locations.
struct LocationReferenceDTO: Decodable {
    let name: String
    let url: String
}

// MARK: - Domain Mapping Extension
extension CharacterDTO {
    /// Maps the data-layer DTO into a Domain entity.
    func toDomain() -> Character {
        return Character(
            id: self.id,
            name: self.name,
            status: CharacterStatus(rawValue: self.status) ?? .unknown,
            species: self.species,
            gender: self.gender,
            imageURLString: self.image,
            originName: self.origin.name,
            locationName: self.location.name,
            episodeURLs: self.episode
        )
    }
}
