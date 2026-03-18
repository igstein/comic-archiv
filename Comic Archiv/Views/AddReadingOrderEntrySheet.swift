//
//  AddReadingOrderEntrySheet.swift
//  Comic Archiv
//

import SwiftUI
import SwiftData

struct AddReadingOrderEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let list: ComicList
    let viewModel: ComicViewModel?

    @State private var searchText: String = ""
    @State private var selectedComic: Comic?
    @State private var showingSuggestions = false

    @Query private var allComics: [Comic]

    private var filteredComics: [Comic] {
        guard !searchText.isEmpty else { return [] }
        let existingIDs = list.readingOrderEntries.compactMap { $0.comic?.id }
        return allComics
            .filter { !existingIDs.contains($0.id) && $0.title.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Comic title or placeholder name")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    TextField("e.g. Batman: Rebirth #1", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 20)
                        .onChange(of: searchText) { _, newValue in
                            showingSuggestions = !newValue.isEmpty
                            selectedComic = nil
                        }

                    if selectedComic != nil {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text("Comic from collection will be added")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                    } else if !searchText.isEmpty && filteredComics.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "cart").foregroundStyle(.orange)
                            Text("A placeholder will be created")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                    }
                }

                Divider().padding(.top, 12)

                if showingSuggestions && !filteredComics.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(filteredComics) { comic in
                                ComicSuggestionRow(comic: comic) { selectComic(comic) }
                                if comic.id != filteredComics.last?.id {
                                    Divider().padding(.leading, 60)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    Spacer()
                }
            }
            .navigationTitle("Add Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addEntry() }.disabled(searchText.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 400)
    }

    private func selectComic(_ comic: Comic) {
        selectedComic = comic
        addEntry()
    }

    private func addEntry() {
        let newPosition = (list.readingOrderEntries.map { $0.position }.max() ?? 0) + 1
        let entry: ReadingOrderEntry

        if let comic = selectedComic {
            entry = ReadingOrderEntry(position: newPosition, comic: comic)
        } else {
            guard let viewModel else {
                let fallback = ReadingOrderEntry(position: newPosition, placeholderName: searchText)
                fallback.list = list
                modelContext.insert(fallback)
                try? modelContext.save()
                dismiss()
                return
            }
            let placeholder = viewModel.createPlaceholder(name: searchText)
            entry = ReadingOrderEntry(position: newPosition, placeholder: placeholder)
        }

        entry.list = list
        modelContext.insert(entry)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Suggestion Row

struct ComicSuggestionRow: View {
    let comic: Comic
    let onSelect: () -> Void

    @State private var coverImage: NSImage?

    var body: some View {
        Button { onSelect() } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2))
                    if let image = coverImage {
                        Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 60).clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Image(systemName: "book.closed").font(.title3).foregroundStyle(.gray)
                    }
                }
                .frame(width: 40, height: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(comic.title).font(.body).fontWeight(.medium).foregroundStyle(.primary)
                    HStack(spacing: 8) {
                        if !comic.author.isEmpty { Text(comic.author).font(.caption).foregroundStyle(.secondary) }
                        if !comic.publisher.isEmpty {
                            Text("•").foregroundStyle(.tertiary)
                            Text(comic.publisher).font(.caption).foregroundStyle(.secondary)
                        }
                        if !comic.issueNumber.isEmpty {
                            Text("•").foregroundStyle(.tertiary)
                            Text("#\(comic.issueNumber)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                if comic.readStatus == .finished {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear { loadCoverImage() }
    }

    private func loadCoverImage() {
        if let fileName = comic.coverImageName {
            coverImage = ImageManager.shared.loadImage(named: fileName)
        }
    }
}
