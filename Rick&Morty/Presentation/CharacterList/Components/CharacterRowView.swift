//
//  CharacterRowView.swift
//  Rick&Morty
//
//  Created by Apple on 13/05/26.
//

import SwiftUI

struct CharacterRowView: View {
    let character: Character
    
    var body: some View {
        HStack(spacing: 14) {
            // Lazy content fetching using default asynchronous styling wrappers
            AsyncImage(url: URL(string: character.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(.systemGray5)
                    .overlay(ProgressView())
            }
            .frame(width: 54, height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusIndicatorColor(character.status))
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
//#Preview {
//    CharacterRowView(character: .init(id: "1", name: "Test Character", imageURL: "", status: "Alive", species: "Human"))
//}