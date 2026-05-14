//
//  Character.swift
//  Rick&Morty
//
//  Created by Apple on 13/05/26.
//

import Foundation

/// Represents the status of a character.
/// a String backing to match the explicit statuses.
enum CharacterStatus: String, Codable {
    case alive = "Alive"
    case dead = "Dead"
    case unknown = "unknown"
}

/// The core business model representing a Character.
/// This object is used by Use Cases and ViewModels
/// from backend DTOs.
struct Character: Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
    let status: CharacterStatus
    let species: String
    let gender: String
    let imageURLString: String
    let originName: String
    let locationName: String
    let episodeURLs: [String]
}
