//
//  ComicDetailView.swift
//  Comic Archiv
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ComicDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let comic: Comic
    
    let viewModel: ComicViewModel
    let onDelete: () -> Void
    
    // State für Bearbeitung (Kopie der Daten)
    @State private var titel: String
    @State private var autor: String
    @State private var zeichner: String
    @State private var verlag: String
    @State private var nummer: String
    @State private var erscheinungsdatum: Date
    @State private var gelesen: Bool
    @State private var coverImage: NSImage?
    
    @State private var showingDeleteAlert = false
    
    init(comic: Comic, viewModel: ComicViewModel, onDelete: @escaping () -> Void) {
        self.comic = comic
        self.viewModel = viewModel
        self.onDelete = onDelete
        
        // Initialisiere State mit aktuellen Werten
        _titel = State(initialValue: comic.titel)
        _autor = State(initialValue: comic.autor)
        _zeichner = State(initialValue: comic.zeichner)
        _verlag = State(initialValue: comic.verlag)
        _nummer = State(initialValue: comic.nummer)
        _erscheinungsdatum = State(initialValue: comic.erscheinungsdatum)
        _gelesen = State(initialValue: comic.gelesen)
        
        // Lade Cover-Bild falls vorhanden
        if let fileName = comic.coverBildName {
            _coverImage = State(initialValue: ImageManager.shared.loadImage(named: fileName))
        }
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
                                .frame(maxHeight: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 300)
                                
                                VStack {
                                    Image(systemName: "book.closed")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.gray)
                                    
                                    Text("Kein Cover vorhanden")
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
                                    Label("Cover entfernen", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Comic löschen", systemImage: "trash")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Comic bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        saveChanges()
                    }
                }
            }
            .alert("Comic löschen?", isPresented: $showingDeleteAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Löschen", role: .destructive) {
                    deleteComic()
                }
            } message: {
                Text("Möchtest du '\(comic.titel)' wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
    
    // MARK: - Image Selection
    
    private func selectImage() {
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .heic, .gif, .bmp, .tiff]
        panel.message = "Wähle ein Cover-Bild"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else {
                return
            }
            
            if let image = NSImage(contentsOf: url) {
                coverImage = image
            }
        }
    }
    
    // MARK: - Save & Delete
    
    private func saveChanges() {
        
        // Textfelder übernehmen
        comic.titel = titel
        comic.autor = autor
        comic.zeichner = zeichner
        comic.verlag = verlag
        comic.nummer = nummer
        comic.erscheinungsdatum = erscheinungsdatum
        comic.gelesen = gelesen
        
        // Cover-Bild speichern
        if let image = coverImage {
            viewModel.setCoverImage(image, for: comic)
        } else if comic.coverBildName != nil {
            viewModel.removeCoverImage(from: comic)
        }
        
        viewModel.updateComic(comic)
        dismiss()
    }
    
    private func deleteComic() {
        viewModel.deleteComic(comic)
        onDelete()
        dismiss()
    }
}
