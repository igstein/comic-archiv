//
//  AddComicSheetForPlaceholder.swift
//  Comic Archiv
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import SwiftData

struct AddComicSheetForPlaceholder: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let entry: ReadingOrderEntry
    let viewModel: ComicViewModel
    
    @State private var titel: String
    @State private var autor = ""
    @State private var zeichner = ""
    @State private var verlag = ""
    @State private var nummer = ""
    @State private var erscheinungsdatum = Date()
    @State private var gelesen = false
    @State private var coverImage: NSImage?
    
    init(entry: ReadingOrderEntry, viewModel: ComicViewModel) {
        self.entry = entry
        self.viewModel = viewModel
        // Titel vom Platzhalter vorausfüllen
        self._titel = State(initialValue: entry.placeholderName ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Comic-Details") {
                    TextField("Titel", text: $titel)
                    TextField("Autor", text: $autor)
                    TextField("Zeichner", text: $zeichner)
                    TextField("Verlag", text: $verlag)
                    TextField("Nummer/Band", text: $nummer)
                }
                
                Section("Weitere Informationen") {
                    DatePicker("Erscheinungsdatum",
                             selection: $erscheinungsdatum,
                             displayedComponents: .date)
                    
                    Toggle("Gelesen", isOn: $gelesen)
                }
                
                Section("Cover-Bild") {
                    VStack(spacing: 12) {
                        // Cover anzeigen
                        if let image = coverImage {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 200)
                                
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.gray)
                                    
                                    Text("Optional")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        // Buttons
                        HStack {
                            Button {
                                selectImage()
                            } label: {
                                Label(coverImage == nil ? "Cover hinzufügen" : "Cover ändern",
                                      systemImage: "photo")
                            }
                            
                            if coverImage != nil {
                                Button(role: .destructive) {
                                    coverImage = nil
                                } label: {
                                    Label("Entfernen", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Comic zur Sammlung hinzufügen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        addComicAndReplacePlaceholder()
                    }
                    .disabled(titel.isEmpty)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 500)
    }
    
    private func selectImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .heic, .gif, .bmp, .tiff]
        panel.message = "Wähle ein Cover-Bild"
        
        panel.begin { response in
            guard response == .OK,
                  let url = panel.url,
                  let image = NSImage(contentsOf: url) else {
                return
            }
            
            coverImage = image
        }
    }
    
    private func addComicAndReplacePlaceholder() {
        // 1. Comic erstellen
        let newComic = Comic(
            titel: titel,
            autor: autor,
            zeichner: zeichner,
            verlag: verlag,
            erscheinungsdatum: erscheinungsdatum,
            nummer: nummer,
            gelesen: gelesen
        )
        
        // 2. Cover-Bild speichern falls vorhanden
        if let image = coverImage {
            viewModel.setCoverImage(image, for: newComic)
        }
        
        // 3. Comic zur "Meine Sammlung" hinzufügen
        modelContext.insert(newComic)
        
        // Hauptliste finden und Comic hinzufügen
        let descriptor = FetchDescriptor<ComicListe>(
            predicate: #Predicate { $0.istHauptliste }
        )
        if let hauptliste = try? modelContext.fetch(descriptor).first {
            hauptliste.comics.append(newComic)
        }
        
        // 4. Platzhalter durch Comic ersetzen
        entry.comic = newComic
        entry.placeholderName = nil
        
        try? modelContext.save()
        
        viewModel.convertPlaceholdersToComic(newComic)
        
        dismiss()
    }
}
