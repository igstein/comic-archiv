//
//  WishlistContentView.swift
//  Comic Archiv
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct WishlistContentView: View {
    let liste: ComicListe
    let viewModel: ComicViewModel?
    
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<PlaceholderComic> { $0.inWishlist == true },
           sort: \PlaceholderComic.name)
    private var placeholders: [PlaceholderComic]
    
    @State private var selectedPlaceholder: PlaceholderComic?
    @State private var showingAddComicSheet = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 24)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            if placeholders.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(placeholders) { placeholder in
                            PlaceholderCardView(
                                placeholder: placeholder,
                                viewModel: viewModel
                            )
                        }
                    }
                    .padding(20)
                }
            }
        }
        .sheet(isPresented: $showingAddComicSheet) {
            if let placeholder = selectedPlaceholder, let viewModel = viewModel {
                AddComicSheetFromWishlist(
                    placeholder: placeholder,
                    viewModel: viewModel
                )
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "cart")
                .font(.title)
                .foregroundStyle(.orange)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Wishlist")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("\(placeholders.count) Comics zu kaufen")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.windowBackgroundColor))
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("Wishlist ist leer")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Platzhalter aus Reading Orders erscheinen hier automatisch.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Placeholder Card

struct PlaceholderCardView: View {
    let placeholder: PlaceholderComic
    let viewModel: ComicViewModel?
    
    @Environment(\.modelContext) private var modelContext
    @State private var isHovering = false
    @State private var showingAddComicSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover Placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.15))
                    .aspectRatio(2/3, contentMode: .fit)
                
                VStack(spacing: 8) {
                    Image(systemName: "cart")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange)
                    
                    Text("Zu kaufen")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(placeholder.name)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                // Anzahl Reading Orders
                let count = placeholder.readingOrderEntries.count
                if count > 0 {
                    Text("In \(count) Reading Order\(count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(
            color: .black.opacity(isHovering ? 0.15 : 0.1),
            radius: isHovering ? 8 : 4,
            y: isHovering ? 4 : 2
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            Button {
                showingAddComicSheet = true
            } label: {
                Label("Zur Sammlung hinzufügen", systemImage: "plus.circle")
            }
            
            Divider()
            
            Button(role: .destructive) {
                deletePlaceholder()
            } label: {
                Label("Von Wishlist entfernen", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingAddComicSheet) {
            if let viewModel = viewModel {
                AddComicSheetFromWishlist(
                    placeholder: placeholder,
                    viewModel: viewModel
                )
            }
        }
    }
    
    private func deletePlaceholder() {
        // Placeholder aus allen Reading Orders entfernen
        for entry in placeholder.readingOrderEntries {
            modelContext.delete(entry)
        }
        
        // Placeholder selbst löschen
        modelContext.delete(placeholder)
        
        try? modelContext.save()
    }
}

// MARK: - Add Comic from Wishlist

struct AddComicSheetFromWishlist: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let placeholder: PlaceholderComic
    let viewModel: ComicViewModel
    
    @State private var titel: String
    @State private var autor = ""
    @State private var zeichner = ""
    @State private var verlag = ""
    @State private var nummer = ""
    @State private var erscheinungsdatum = Date()
    @State private var gelesen = false
    @State private var coverImage: NSImage?
    
    init(placeholder: PlaceholderComic, viewModel: ComicViewModel) {
        self.placeholder = placeholder
        self.viewModel = viewModel
        self._titel = State(initialValue: placeholder.name)
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
                    coverSection
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
                        addComic()
                    }
                    .disabled(titel.isEmpty)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 500)
    }
    
    private var coverSection: some View {
        VStack(spacing: 12) {
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
    
    private func addComic() {
        // Comic erstellen
        let newComic = Comic(
            titel: titel,
            autor: autor,
            zeichner: zeichner,
            verlag: verlag,
            erscheinungsdatum: erscheinungsdatum,
            nummer: nummer,
            gelesen: gelesen
        )
        
        // Cover speichern
        if let image = coverImage {
            viewModel.setCoverImage(image, for: newComic)
        }
        
        // Zur Hauptliste hinzufügen
        let descriptor = FetchDescriptor<ComicListe>(
            predicate: #Predicate { $0.istHauptliste }
        )
        if let hauptliste = try? modelContext.fetch(descriptor).first {
            viewModel.addComic(newComic, toListe: hauptliste)
        } else {
            modelContext.insert(newComic)
        }
        
        // Alle Platzhalter konvertieren (inkl. diesem)
        viewModel.convertPlaceholdersToComic(newComic)
        
        dismiss()
    }
}
