//
//  Episode.swift
//  Rick&Morty
//
//  Created by Apple on 13/05/26.
//

import Foundation

/// Represents the minimalist Episode details required
/// to be displayed on the Character Detail dashboard.
struct Episode: Identifiable, Equatable {
    let id: Int
    let name: String
    let airDate: String
    let episodeCode: String
}
