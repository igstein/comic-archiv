//
//  AddReadingOrderEntrySheet.swift
//  Comic Archiv
//

import SwiftUI
import SwiftData

struct AddReadingOrderEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let liste: ComicListe
    let viewModel: ComicViewModel?
    
    @State private var searchText: String = ""
    @State private var selectedComic: Comic?
    @State private var showingSuggestions = false
    
    @Query private var allComics: [Comic]
    
    // Gefilterte Comics für Autocomplete
    private var filteredComics: [Comic] {
        guard !searchText.isEmpty else { return [] }
        
        // Comics die NICHT bereits in dieser Reading Order sind
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
                    Text("Comic-Titel oder Platzhalter-Name")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    TextField("z.B. Batman: Rebirth #1", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 20)
                        .onChange(of: searchText) { oldValue, newValue in
                            showingSuggestions = !newValue.isEmpty
                            selectedComic = nil
                        }
                    
                    // Info Text
                    if selectedComic != nil {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Comic aus Sammlung wird hinzugefügt")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                    } else if !searchText.isEmpty && filteredComics.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "cart")
                                .foregroundStyle(.orange)
                            Text("Platzhalter wird erstellt (Comic noch nicht in Sammlung)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Divider()
                    .padding(.top, 12)
                
                // Suggestions List
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
                } else {
                    Spacer()
                }
            }
            .navigationTitle("Eintrag hinzufügen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        addEntry()
                    }
                    .disabled(searchText.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    // MARK: - Actions
    
    private func selectComic(_ comic: Comic) {
        selectedComic = comic
        addEntry()
    }
    
    private func addEntry() {
        let newPosition = (liste.readingOrderEntries.map { $0.position }.max() ?? 0) + 1
        
        let entry: ReadingOrderEntry
        
        if let comic = selectedComic {
            // Comic aus Sammlung
            entry = ReadingOrderEntry(position: newPosition, comic: comic)
        } else {
            // PlaceholderComic erstellen statt String
            guard let viewModel = viewModel else {
                // Fallback: alter Weg (sollte nicht passieren)
                entry = ReadingOrderEntry(position: newPosition, placeholderName: searchText)
                entry.liste = liste
                modelContext.insert(entry)
                try? modelContext.save()
                dismiss()
                return
            }
            
            let placeholder = viewModel.createPlaceholder(name: searchText)
            entry = ReadingOrderEntry(position: newPosition, placeholder: placeholder)
        }
        
        entry.liste = liste
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
        Button {
            onSelect()
        } label: {
            HStack(spacing: 12) {
                // Cover
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    if let image = coverImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Image(systemName: "book.closed")
                            .font(.title3)
                            .foregroundStyle(.gray)
                    }
                }
                .frame(width: 40, height: 60)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(comic.titel)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 8) {
                        if !comic.autor.isEmpty {
                            Text(comic.autor)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if !comic.verlag.isEmpty {
                            Text("•")
                                .foregroundStyle(.tertiary)
                            Text(comic.verlag)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if !comic.nummer.isEmpty {
                            Text("•")
                                .foregroundStyle(.tertiary)
                            Text("#\(comic.nummer)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Status
                if comic.gelesen {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear {
            loadCoverImage()
        }
    }
    
    private func loadCoverImage() {
        if let fileName = comic.coverBildName {
            coverImage = ImageManager.shared.loadImage(named: fileName)
        }
    }
}
