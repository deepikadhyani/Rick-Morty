//
//  CharacterDetailView.swift
//  Rick&Morty
//
//  Created by Apple on 13/05/26.
//

import SwiftUI
import SDWebImageSwiftUI

struct CharacterDetailView: View {
    @StateObject private var viewModel: CharacterDetailViewModel
    
    // Internal initializer to keep @StateObject safe
    init(viewModel: CharacterDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        List {
            // Profile Info Header Layout Section
            Section {
                VStack(alignment: .center, spacing: 12) {
                    
                    // image loading
                    WebImage(url: URL(string: viewModel.character.imageURLString))
                        .resizable()
                        .indicator(.activity)
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                        .frame(maxWidth: .infinity)
                    
                    Text(viewModel.character.name)
                        .font(.title2.bold())
                    
                    Text("\(viewModel.character.species) • \(viewModel.character.status)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            // Core Spec Properties Detail Section
            Section(header: Text("Details")) {
                DetailLabeledRow(label: "Gender", value: viewModel.character.gender)
                DetailLabeledRow(label: "Origin", value: viewModel.character.originName)
                DetailLabeledRow(label: "Location", value: viewModel.character.locationName)
            }
            
            // Episode Loading Dynamic Grid Section
            Section(header: Text("Featured Episodes")) {
                episodesContentList()
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(viewModel.character.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadEpisodes()
        }
    }
    
    // MARK: - Sub-Views
    
    @ViewBuilder
    private func episodesContentList() -> some View {
        switch viewModel.state {
        case .idle, .loading:
            HStack {
                Spacer()
                ProgressView("Resolving metadata...")
                Spacer()
            }
            
        case .error(let errorText):
            Text(errorText)
                .foregroundColor(.red)
                .font(.caption)
            
        case .loaded(let episodes):
            if episodes.isEmpty {
                Text("No featured episodes recorded.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                ForEach(episodes) { episode in
                    HStack {
                        Text(episode.name)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(episode.airDate)
                            .font(.caption)
                            .foregroundColor(.brown)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

struct DetailLabeledRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.light)
                .foregroundColor(.accentColor)
        }
    }
}

