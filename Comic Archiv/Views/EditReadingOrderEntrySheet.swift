//
//  EditReadingOrderEntrySheet.swift
//  Comic Archiv
//

import SwiftUI
import SwiftData

// MARK: - Edit Platzhalter

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
                Section("Titel") {
                    TextField("z.B. Batman: Rebirth #1", text: $name)
                }
            }
            .navigationTitle("Platzhalter bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        savePlaceholder()
                    }
                    .disabled(name.isEmpty)
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

// MARK: - Convert Platzhalter zu Comic

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
        guard !searchText.isEmpty else { return [] }
        
        // Comics die NICHT bereits in dieser Reading Order sind
        guard let liste = entry.liste else { return [] }
        let existingComicIDs = liste.readingOrderEntries.compactMap { $0.comic?.id }
        
        return allComics.filter { comic in
            !existingComicIDs.contains(comic.id) &&
            comic.titel.localizedCaseInsensitiveContains(searchText)
        }
        .sorted { $0.titel.localizedCompare($1.titel) == .orderedAscending }
        .prefix(5)
        .map { $0 }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Comic aus Sammlung wählen")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    TextField("Comic suchen...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 20)
                        .onChange(of: searchText) { oldValue, newValue in
                            showingSuggestions = !newValue.isEmpty
                            selectedComic = nil
                        }
                    
                    // Info
                    if let comic = selectedComic {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Comic wird zugeordnet: \(comic.titel)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Divider()
                    .padding(.top, 12)
                
                // Suggestions
                if showingSuggestions && !filteredComics.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(filteredComics) { comic in
                                ComicSuggestionRow(comic: comic) {
                                    selectComic(comic)
                                }
                                
                                if comic.id != filteredComics.last?.id {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } else if !searchText.isEmpty && filteredComics.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Kein Comic gefunden")
                            .font(.headline)
                        Text("Füge den Comic erst zu deiner Sammlung hinzu.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Spacer()
                }
            }
            .navigationTitle("In Comic umwandeln")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Umwandeln") {
                        convertToComic()
                    }
                    .disabled(selectedComic == nil)
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    private func selectComic(_ comic: Comic) {
        selectedComic = comic
        searchText = comic.titel
        showingSuggestions = false
    }
    
    private func convertToComic() {
        guard let comic = selectedComic else { return }
        
        // Platzhalter in Comic umwandeln
        entry.comic = comic
        entry.placeholderName = nil
        
        try? modelContext.save()
        dismiss()
    }
}
