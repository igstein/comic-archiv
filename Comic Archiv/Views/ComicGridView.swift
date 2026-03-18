//
//  ComicGridView.swift
//  Comic Archiv
//

import SwiftUI

struct ComicGridView: View {
    let comics: [Comic]
    let onAddComic: () -> Void
    let viewModel: ComicViewModel?
    
    @State private var selectedComic: Comic?
    
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 24)
    ]
    
    var body: some View {
        Group {
            if comics.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(comics) { comic in
                            ComicCardView(comic: comic) {
                                selectedComic = comic
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(20)
                    .animation(.spring(response: 0.3), value: comics.count)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    onAddComic()
                } label: {
                    Label("Comic hinzufügen", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
                .help("Neuen Comic hinzufügen (⌘N)")
            }
        }
        .sheet(item: $selectedComic) { comic in
            if let viewModel = viewModel {
                ComicDetailView(
                    comic: comic,
                    viewModel: viewModel,
                    onDelete: {
                        selectedComic = nil
                    }
                )
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("Keine Comics")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Füge deinen ersten Comic hinzu oder ziehe Comics aus anderen Listen hierher")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                onAddComic()
            } label: {
                Label("Comic hinzufügen", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
