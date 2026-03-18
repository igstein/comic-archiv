//
//  SidebarView.swift
//  Comic Archiv
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SidebarView: View {
    let listen: [ComicListe]
    let comics: [Comic]
    @Binding var selectedListe: ComicListe?
    let viewModel: ComicViewModel?
    
    @State private var showingAddListe = false
    @State private var showingAddReadingOrder = false
    @State private var listeToEdit: ComicListe?
    @State private var listeToDelete: ComicListe?
    @State private var showingDeleteAlert = false
    @State private var dropTargetListe: ComicListe?
    
    private var normaleListen: [ComicListe] {
        listen.filter { !$0.istReadingOrder && !$0.istHauptliste && !$0.istWishlist }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
    
    private var hauptliste: ComicListe? {
        listen.first { $0.istHauptliste }
    }
    
    private var wishlist: ComicListe? {
        listen.first { $0.istWishlist }
    }
    
    private var readingOrders: [ComicListe] {
        listen.filter { $0.istReadingOrder }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
    
    var body: some View {
        List(selection: $selectedListe) {
            // System-Listen (immer oben)
            Section("Listen") {
                // 1. Meine Sammlung
                if let hauptliste = hauptliste {
                    ListeRowView(
                        liste: hauptliste,
                        isDropTarget: dropTargetListe?.id == hauptliste.id,
                        onEdit: {
                            listeToEdit = hauptliste
                        },
                        onDelete: {
                            // Kann nicht gelöscht werden
                        }
                    )
                    .tag(hauptliste)
                    .onDrop(
                        of: [UTType.text],
                        isTargeted: createBinding(for: hauptliste)
                    ) { providers in
                        handleDrop(providers: providers, toListe: hauptliste)
                    }
                }
                
                // 2. Wishlist
                if let wishlist = wishlist {
                    WishlistSidebarRowView(liste: wishlist)
                        .tag(wishlist)
                }
                
                // 3. Normale Listen (alphabetisch sortiert)
                ForEach(normaleListen) { liste in
                    ListeRowView(
                        liste: liste,
                        isDropTarget: dropTargetListe?.id == liste.id,
                        onEdit: {
                            listeToEdit = liste
                        },
                        onDelete: {
                            listeToDelete = liste
                            showingDeleteAlert = true
                        }
                    )
                    .tag(liste)
                    .onDrop(
                        of: [UTType.text],
                        isTargeted: createBinding(for: liste)
                    ) { providers in
                        handleDrop(providers: providers, toListe: liste)
                    }
                }
            }
            
            // Reading Orders
            Section("Reading Orders") {
                ForEach(readingOrders) { liste in
                    ReadingOrderRowView(
                        liste: liste,
                        onEdit: {
                            listeToEdit = liste
                        },
                        onDelete: {
                            listeToDelete = liste
                            showingDeleteAlert = true
                        },
                        viewModel: viewModel,
                        allComics: comics
                    )
                    .tag(liste)
                }
            }
        }
        .navigationTitle("Comic Archiv")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showingAddListe = true
                } label: {
                    Label("Neue Liste", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button {
                    showingAddReadingOrder = true
                } label: {
                    Label("Neue Reading Order", systemImage: "list.number")
                }
            }
        }
        .sheet(isPresented: $showingAddListe) {
            if let viewModel = viewModel {
                AddListeSheet(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingAddReadingOrder) {
            if let viewModel = viewModel {
                AddReadingOrderSheet(viewModel: viewModel)
            }
        }
        .sheet(item: $listeToEdit) { liste in
            if let viewModel = viewModel {
                EditListeSheet(liste: liste, viewModel: viewModel)
            }
        }
        .alert("Liste löschen?", isPresented: $showingDeleteAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                if let liste = listeToDelete {
                    deleteListe(liste)
                }
            }
        } message: {
            if let liste = listeToDelete {
                if liste.istReadingOrder {
                    Text("Möchtest du die Reading Order '\(liste.name)' wirklich löschen? Die Comics bleiben erhalten.")
                } else {
                    Text("Möchtest du die Liste '\(liste.name)' wirklich löschen? Die Comics bleiben erhalten.")
                }
            }
        }
    }
    
    private func createBinding(for liste: ComicListe) -> Binding<Bool> {
        Binding(
            get: { dropTargetListe?.id == liste.id },
            set: { isTargeted in
                if isTargeted {
                    dropTargetListe = liste
                } else if dropTargetListe?.id == liste.id {
                    dropTargetListe = nil
                }
            }
        )
    }
    
    private func handleDrop(providers: [NSItemProvider], toListe liste: ComicListe) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let uuidString = String(data: data, encoding: .utf8),
                  let uuid = UUID(uuidString: uuidString),
                  let comic = comics.first(where: { $0.id == uuid }),
                  let viewModel = viewModel else {
                return
            }
            
            DispatchQueue.main.async {
                viewModel.addComicToListe(comic, liste: liste)
                dropTargetListe = nil
            }
        }
        
        return true
    }
    
    private func deleteListe(_ liste: ComicListe) {
        if selectedListe?.id == liste.id {
            selectedListe = listen.first
        }
        viewModel?.deleteListe(liste)
    }
}

// Bestehende Row-View für normale Listen
struct ListeRowView: View {
    let liste: ComicListe
    let isDropTarget: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Icon
            if let iconName = liste.icon {
                Image(systemName: iconName)
                    .foregroundStyle(liste.istHauptliste ? .blue : (liste.istWishlist ? .orange : .secondary))
                    .font(.body)
                    .frame(width: 20)
            }
            
            // Name
            Text(liste.name)
                .fontWeight(liste.istHauptliste ? .semibold : .regular)
            
            Spacer()
            
            // Comic-Anzahl
            Text("\(liste.comics.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                )
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isDropTarget ? Color.accentColor.opacity(0.2) : Color.clear)
        )
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Umbenennen", systemImage: "pencil")
            }
            
            if !liste.istHauptliste && !liste.istWishlist {
                Divider()
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Löschen", systemImage: "trash")
                }
            }
        }
    }
}

// Row-View für Reading Orders (vereinfacht)
struct ReadingOrderRowView: View {
    let liste: ComicListe
    let onEdit: () -> Void
    let onDelete: () -> Void
    let viewModel: ComicViewModel?
    let allComics: [Comic]
    
    @State private var isDropTarget = false
    @State private var showingDuplicateAlert = false
    
    private var progressText: String {
        if let progress = liste.readingProgress, progress.gesamt > 0 {
            return "\(progress.gelesen)/\(progress.gesamt) gelesen"
        }
        return ""
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: liste.icon ?? "list.number")
                .foregroundStyle(.orange)
                .font(.body)
                .frame(width: 20)
            
            // Name & Fortschritt
            VStack(alignment: .leading, spacing: 2) {
                Text(liste.name)
                    .fontWeight(.regular)
                
                if !progressText.isEmpty {
                    Text(progressText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Entry-Anzahl Badge
            badgeView
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isDropTarget ? Color.accentColor.opacity(0.2) : Color.clear)
        )
        .contentShape(Rectangle())
        .onDrop(of: [UTType.text], isTargeted: $isDropTarget) { providers in
            handleComicDrop(providers: providers)
        }
        .contextMenu {
            contextMenuContent
        }
        .alert("Comic bereits vorhanden", isPresented: $showingDuplicateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Dieser Comic ist bereits in dieser Reading Order enthalten.")
        }
    }
    
    private var badgeView: some View {
        Text("\(liste.readingOrderEntries.count)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.15))
            )
    }
    
    @ViewBuilder
    private var contextMenuContent: some View {
        Button {
            onEdit()
        } label: {
            Label("Umbenennen", systemImage: "pencil")
        }
        
        Divider()
        
        Button(role: .destructive) {
            onDelete()
        } label: {
            Label("Löschen", systemImage: "trash")
        }
    }
    
    // MARK: - Drop Handler
    
    private func handleComicDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let uuidString = String(data: data, encoding: .utf8),
                  let uuid = UUID(uuidString: uuidString),
                  let comic = allComics.first(where: { $0.id == uuid }),
                  let viewModel = viewModel else {
                return
            }
            
            DispatchQueue.main.async {
                let success = viewModel.addComicToReadingOrder(comic, readingOrder: liste)
                if !success {
                    showingDuplicateAlert = true
                }
            }
        }
        
        return true
    }
}

// Row-View für Wishlist
struct WishlistRowView: View {
    let liste: ComicListe
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: liste.icon ?? "cart")
                .foregroundStyle(.orange)
                .font(.body)
                .frame(width: 20)
            
            Text(liste.name)
                .fontWeight(.regular)
            
            Spacer()
            
            // Anzahl der Platzhalter (wird spÃ¤ter befÃ¼llt)
            Text("0")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                )
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
}

// Wishlist Row mit Platzhalter-Count
struct WishlistSidebarRowView: View {
    let liste: ComicListe
    
    @Query(filter: #Predicate<PlaceholderComic> { $0.inWishlist == true })
    private var placeholders: [PlaceholderComic]
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: liste.icon ?? "cart")
                .foregroundStyle(.orange)
                .font(.body)
                .frame(width: 20)
            
            Text(liste.name)
            
            Spacer()
            
            Text("\(placeholders.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                )
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
}
