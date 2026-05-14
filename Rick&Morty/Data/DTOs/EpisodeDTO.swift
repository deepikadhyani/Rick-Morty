//
//  EpisodeDTO.swift
//  Rick&Morty
//
//  Created by Apple on 13/05/26.
//

import Foundation

/// Data Transfer Object representing the raw JSON payload structure for an episode.
struct EpisodeDTO: Codable {
    let id: Int
    let name: String
    let air_date: String
    let episode: String
    let characters: [String]
    let url: String
    let created: String
    
    // MARK: - Domain Mapping Extension
    /// Converts the low-level data layer DTO into Domain model.
    func toDomain() -> Episode {
        return Episode(
            id: self.id,
            name: self.name,
            airDate: self.air_date,
            episodeCode: self.episode
        )
    }
}

