//
//  MainView.swift (Alternative mit Segmented Control)
//  Comic Archiv
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var comics: [Comic]
    @Query private var listen: [ComicListe]
    
    @State private var selectedListe: ComicListe?
    @State private var showingAddComic = false
    @State private var viewModel: ComicViewModel?
    @State private var sortOrder: SortOrder = .title
    @State private var searchText = ""
    @State private var gelesenFilter: GelesenFilter = .alle
    
    enum SortOrder: String, CaseIterable {
        case title = "Titel"
        case author = "Autor"
        case publisher = "Verlag"
        case date = "Datum"
        
        var icon: String {
            switch self {
            case .title: return "textformat"
            case .author: return "person"
            case .publisher: return "building.2"
            case .date: return "calendar"
            }
        }
    }
    
    // Gelesen-Status Filter Enum
    enum GelesenFilter: String, CaseIterable, Identifiable {
        case alle = "Alle"
        case gelesen = "Gelesen"
        case ungelesen = "Ungelesen"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            SidebarView(
                listen: listen,
                comics: comics,
                selectedListe: $selectedListe,
                viewModel: viewModel
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            // Hauptbereich
            if let liste = selectedListe {
                if liste.istReadingOrder {
                    // Reading Order View
                    ReadingOrderContentView(
                        liste: liste,
                        viewModel: viewModel
                    )
                } else if liste.istWishlist {
                    // Wishlist View
                    WishlistContentView(
                        liste: liste,
                        viewModel: viewModel
                    )
                } else {
                    // Normale Grid View
                    VStack(spacing: 0) {
                        // Header mit Info
                        VStack(spacing: 0) {
                            HStack(alignment: .center, spacing: 12) {
                                // ... bestehender header code ...
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(Color(.windowBackgroundColor))
                        }
                        
                        Divider()
                        
                        // Comic Grid
                        ComicGridView(
                            comics: sortedComics,
                            onAddComic: { showingAddComic = true },
                            viewModel: viewModel
                        )
                        .searchable(
                            text: $searchText,
                            placement: .toolbar,
                            prompt: "Comics durchsuchen..."
                        )
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Sortierung
                Menu {
                    Picker("Sortierung", selection: $sortOrder) {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Label(order.rawValue, systemImage: order.icon)
                                .tag(order)
                        }
                    }
                } label: {
                    Label("Sortierung", systemImage: "arrow.up.arrow.down")
                }
                .help("Sortierung ändern")
            }
        }
        .onAppear {
            // ViewModel initialisieren
            if viewModel == nil {
                viewModel = ComicViewModel(modelContext: modelContext)
            }
            
            // System-Listen sicherstellen (Meine Sammlung + Wishlist)
            ensureSystemListsExist()
            
            // Erste Liste auswählen
            if selectedListe == nil, let erste = listen.first {
                selectedListe = erste
            }
        }
        .sheet(isPresented: $showingAddComic) {
            if let viewModel = viewModel {
                AddComicSheet(
                    viewModel: viewModel,
                    targetListe: selectedListe
                )
            }
        }
        .navigationTitle(selectedListe?.name ?? "Comic Archiv")
    }
    
    // Gefilterte Comics basierend auf ausgewählter Liste
    private var filteredComics: [Comic] {
        guard let selectedListe = selectedListe else {
            return comics
        }
        return selectedListe.comics
    }

    // Gefilterte Comics mit Suche UND Gelesen-Status
    private var searchFilteredComics: [Comic] {
        var result = filteredComics
        
        // 1. Suche anwenden
        if !searchText.isEmpty {
            result = result.filter { comic in
                comic.titel.localizedCaseInsensitiveContains(searchText) ||
                comic.autor.localizedCaseInsensitiveContains(searchText) ||
                comic.verlag.localizedCaseInsensitiveContains(searchText) ||
                comic.nummer.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 2. Gelesen-Status Filter anwenden
        switch gelesenFilter {
        case .alle:
            break // Keine weitere Filterung
        case .gelesen:
            result = result.filter { $0.gelesen }
        case .ungelesen:
            result = result.filter { !$0.gelesen }
        }
        
        return result
    }
    
    // Sortierte Comics
    private var sortedComics: [Comic] {
        let filtered = searchFilteredComics
        
        switch sortOrder {
        case .title:
            return filtered.sorted { $0.titel.localizedCompare($1.titel) == .orderedAscending }
        case .author:
            return filtered.sorted { $0.autor.localizedCompare($1.autor) == .orderedAscending }
        case .publisher:
            return filtered.sorted { $0.verlag.localizedCompare($1.verlag) == .orderedAscending }
        case .date:
            return filtered.sorted { $0.erscheinungsdatum > $1.erscheinungsdatum }
        }
    }
    
    // System-Listen sicherstellen
    private func ensureSystemListsExist() {
        // Meine Sammlung erstellen falls nicht vorhanden
        let hauptlisteDescriptor = FetchDescriptor<ComicListe>(
            predicate: #Predicate { $0.istHauptliste }
        )
        let existingHauptliste = try? modelContext.fetch(hauptlisteDescriptor).first
        
        if existingHauptliste == nil {
            let hauptliste = ComicListe(
                name: "Meine Sammlung",
                icon: "books.vertical.fill",
                istHauptliste: true
            )
            modelContext.insert(hauptliste)
        }
        
        // Wishlist erstellen falls nicht vorhanden
        viewModel?.ensureWishlistExists()
        
        try? modelContext.save()
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Comic.self, ComicListe.self], inMemory: true)
}
