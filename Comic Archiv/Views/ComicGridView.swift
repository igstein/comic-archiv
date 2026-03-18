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

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 24)]

    var body: some View {
        Group {
            if comics.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(comics) { comic in
                            ComicCardView(comic: comic) { selectedComic = comic }
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
                Button { onAddComic() } label: {
                    Label("Add Comic", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
                .help("Add new comic (⌘N)")
            }
        }
        .sheet(item: $selectedComic) { comic in
            if let viewModel {
                ComicDetailView(comic: comic, viewModel: viewModel) {
                    selectedComic = nil
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Comics")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add your first comic or drag comics from other lists here.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button { onAddComic() } label: {
                Label("Add Comic", systemImage: "plus.circle.fill").font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
