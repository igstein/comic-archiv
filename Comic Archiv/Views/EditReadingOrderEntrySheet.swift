//
//  EditReadingOrderEntrySheet.swift
//  Comic Archiv
//

import SwiftUI
import SwiftData

// MARK: - Edit Placeholder Title

struct EditPlaceholderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let entry: ReadingOrderEntry
    @State private var name: String

    init(entry: ReadingOrderEntry) {
        self.entry = entry
        self._name = State(initialValue: entry.placeholderName ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("e.g. Batman: Rebirth #1", text: $name)
                }
            }
            .navigationTitle("Edit Placeholder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { savePlaceholder() }.disabled(name.isEmpty)
                }
            }
        }
        .frame(width: 400, height: 200)
    }

    private func savePlaceholder() {
        entry.placeholderName = name
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Convert Placeholder to Comic

struct ConvertPlaceholderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let entry: ReadingOrderEntry
    @State private var searchText: String
    @State private var selectedComic: Comic?
    @State private var showingSuggestions = false

    @Query private var allComics: [Comic]

    init(entry: ReadingOrderEntry) {
        self.entry = entry
        self._searchText = State(initialValue: entry.placeholderName ?? "")
    }

    private var filteredComics: [Comic] {
        guard !searchText.isEmpty, let list = entry.list else { return [] }
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
                    Text("Choose a comic from your collection")
                        .font(.headline).padding(.horizontal, 20).padding(.top, 20)

                    TextField("Search comics...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 20)
                        .onChange(of: searchText) { _, newValue in
                            showingSuggestions = !newValue.isEmpty
                            selectedComic = nil
                        }

                    if let comic = selectedComic {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text("Will link to: \(comic.title)").font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                    }
                }

                Divider().padding(.top, 12)

                if showingSuggestions && !filteredComics.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(filteredComics) { comic in
                                ComicSuggestionRow(comic: comic) {
                                    selectedComic = comic
                                    searchText = comic.title
                                    showingSuggestions = false
                                }
                                if comic.id != filteredComics.last?.id {
                                    Divider().padding(.leading, 60)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } else if !searchText.isEmpty && filteredComics.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass").font(.largeTitle).foregroundStyle(.secondary)
                        Text("No comic found").font(.headline)
                        Text("Add the comic to your collection first.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Spacer()
                }
            }
            .navigationTitle("Convert to Comic")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Convert") { convertToComic() }.disabled(selectedComic == nil)
                }
            }
        }
        .frame(width: 500, height: 400)
    }

    private func convertToComic() {
        guard let comic = selectedComic else { return }
        entry.comic = comic
        entry.placeholderName = nil
        try? modelContext.save()
        dismiss()
    }
}
