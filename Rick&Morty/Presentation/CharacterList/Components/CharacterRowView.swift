//
//  CharacterRowView.swift
//  Rick&Morty
//
//  Created by Apple on 13/05/26.
//

import SwiftUI
import SDWebImageSwiftUI

struct CharacterRowView: View {
    let character: Character
    
    var body: some View {
        HStack(spacing: 14) {
            
            // image loading
            WebImage(url: URL(string: character.imageURLString))
                .resizable()
                .indicator(.activity)
                .frame(width: 54, height: 54)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusIndicatorColor(character.status.rawValue))
                        .frame(width: 8, height: 8)
                    
                    Text("\(character.status) — \(character.species)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private func statusIndicatorColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "alive": return .green
        case "dead": return .red
        default: return .gray
        }
    }
}

