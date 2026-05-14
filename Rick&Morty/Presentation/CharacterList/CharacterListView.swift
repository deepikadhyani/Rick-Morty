//
//  CharacterListView.swift
//  Rick&Morty
//
//  Created by Apple on 13/05/26.
//

import SwiftUI

struct CharacterListView: View {
    @StateObject var viewModel: CharacterListViewModel
    
    let detailViewProvider: (Character) -> CharacterDetailView
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Input Layer bound directly to debouncing property
                CustomSearchBar(text: $viewModel.searchQueryString)
                
                // Deterministic UI state machine processing matching exact Enum
                switch viewModel.state {
                case .loading:
                    Spacer()
                    ProgressView("Loading Characters...")
                        .scaleEffect(1.2)
                    Spacer()
                    
                case .empty:
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("No characters found")
                            .font(.headline)
                        Text("Try refining your search terms parameters.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                case .error(let errorMessage):
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.icloud")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Retry Connection") {
                            Task {
                                await viewModel.retry()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                case .loaded(let characters):
                    List {
                        ForEach(characters) { character in
                            NavigationLink(value: character) {
                                CharacterRowView(character: character)
                            }
                            .onAppear {
                                // Calls pagination logic when a row surfaces
                                viewModel.handleItemAppearance(character)
                            }
                        }
                        
                        // Bottom pagination loader
                        if viewModel.isIncrementallyLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding(.vertical, 16)
                            .listRowSeparator(.visible)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .padding(.top, -8)
                }
            }
            .navigationTitle("Characters")
            .navigationDestination(for: Character.self) { character in
                detailViewProvider(character)
            }
            .task {
                // initial data retrieval call hook
                await viewModel.loadInitialContent()
            }
        }
    }
}

// MARK: - Extracted Pure SwiftUI Subviews

struct CustomSearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search characters by name...", text: $text)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

