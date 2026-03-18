//
//  ReadingOrderContentView.swift
//  Comic Archiv
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ReadingOrderContentView: View {
    let liste: ComicListe
    let viewModel: ComicViewModel?
    
    @State private var showingAddEntry = false
    @State private var showingDuplicateAlert = false
    @State private var isDropTarget = false
    @Environment(\.modelContext) private var modelContext
    
    @Query private var allComics: [Comic]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header mit Fortschritt
            headerView
            
            Divider()
            
            // Entries Liste
            if liste.readingOrderEntries.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(liste.sortedReadingOrderEntries, id: \.id) { entry in
                            ReadingOrderEntryRow(entry: entry, viewModel: viewModel)
                                .onDrop(of: [.text], delegate: DropViewDelegate(
                                    item: entry,
                                    liste: liste,
                                    modelContext: modelContext
                                ))
                            
                            if entry.id != liste.sortedReadingOrderEntries.last?.id {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDropTarget ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .onDrop(of: [UTType.text], isTargeted: $isDropTarget) { providers in
            handleComicDrop(providers: providers)
        }
        .sheet(isPresented: $showingAddEntry) {
            AddReadingOrderEntrySheet(
                liste: liste,
                viewModel: viewModel
            )
        }
        .alert("Comic bereits vorhanden", isPresented: $showingDuplicateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Dieser Comic ist bereits in dieser Reading Order enthalten.")
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: liste.icon ?? "list.number")
                .font(.title)
                .foregroundStyle(.orange)
                .frame(width: 32, height: 32)
            
            // Name & Fortschritt
            VStack(alignment: .leading, spacing: 4) {
                Text(liste.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let progress = liste.readingProgress {
                    HStack(spacing: 12) {
                        Label("\(progress.gelesen)/\(progress.gesamt) gelesen", systemImage: "checkmark.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if progress.zuKaufen > 0 {
                            Label("\(progress.zuKaufen) zu kaufen", systemImage: "cart")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Add Button
            Button {
                showingAddEntry = true
            } label: {
                Label("Hinzufügen", systemImage: "plus.circle.fill")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.windowBackgroundColor))
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("Keine Einträge")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Füge Comics oder Platzhalter hinzu, um deine Reading Order zu erstellen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            
            Button {
                showingAddEntry = true
            } label: {
                Label("Ersten Eintrag hinzufügen", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    // Comic ist bereits in der Liste
                    showingDuplicateAlert = true
                }
            }
        }
        
        return true
    }
}

// MARK: - Entry Row

struct ReadingOrderEntryRow: View {
    let entry: ReadingOrderEntry
    let viewModel: ComicViewModel?
    @Environment(\.modelContext) private var modelContext
    
    @State private var coverImage: NSImage?
    @State private var isHovering = false
    @State private var isDragging = false
    @State private var showingEditSheet = false
    @State private var showingAddComicSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Position Nummer
            Text("\(entry.position).")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .trailing)
            
            // Status Icon
            Image(systemName: statusIcon)
                .font(.title3)
                .foregroundStyle(statusColor)
                .frame(width: 24)
            
            // Cover (klein)
            coverView
                .frame(width: 40, height: 60)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                
                if let comic = entry.comic {
                    HStack(spacing: 8) {
                        if !comic.autor.isEmpty {
                            Text(comic.autor)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if !comic.verlag.isEmpty {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 4))
                                .foregroundStyle(.tertiary)
                            Text(comic.verlag)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if !comic.nummer.isEmpty {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 4))
                                .foregroundStyle(.tertiary)
                            Text("#\(comic.nummer)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Noch nicht in Sammlung")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            Spacer()
            
            // Status Badge
            statusBadge
            
            // Drag Handle
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
                .font(.body)
                .opacity(isHovering ? 1.0 : 0.0)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isDragging ? Color.accentColor.opacity(0.1) : (isHovering ? Color.secondary.opacity(0.05) : Color.clear))
        )
        .opacity(isDragging ? 0.5 : 1.0)
        .onHover { hovering in
            isHovering = hovering
        }
        .onAppear {
            loadCoverImage()
        }
        .onChange(of: entry.comic?.coverBildName) { oldValue, newValue in
            if newValue != nil {
                loadCoverImage()
            }
        }
        .contextMenu {
            contextMenuContent
        }
        .sheet(isPresented: $showingEditSheet) {
                    EditPlaceholderSheet(entry: entry)
                }
        .sheet(isPresented: $showingAddComicSheet) {
            if let viewModel = viewModel {
                AddComicSheetForPlaceholder(
                    entry: entry,
                    viewModel: viewModel
                )
            }
        }
        .contentShape(Rectangle())
        .onDrag {
            isDragging = true
            
            // Nach kurzem Delay wieder normal anzeigen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isDragging = false
            }
            
            // Entry ID als Drag-Daten
            return NSItemProvider(object: entry.id.uuidString as NSString)
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusIcon: String {
        if entry.isPlaceholder {
            return "cart"
        } else if entry.comic?.gelesen == true {
            return "checkmark.circle.fill"
        } else {
            return "book"
        }
    }
    
    private var statusColor: Color {
        if entry.isPlaceholder {
            return .orange
        } else if entry.comic?.gelesen == true {
            return .green
        } else {
            return .blue
        }
    }
    
    private var statusBadge: some View {
        Group {
            if entry.isPlaceholder {
                Text("Zu kaufen")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.15))
                    )
            } else if entry.comic?.gelesen == true {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            }
        }
    }
    
    // MARK: - Cover View
    
    @ViewBuilder
    private var coverView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
            
            if let image = coverImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else if entry.isPlaceholder {
                Image(systemName: "cart")
                    .font(.title3)
                    .foregroundStyle(.gray)
            } else {
                Image(systemName: "book.closed")
                    .font(.title3)
                    .foregroundStyle(.gray)
            }
        }
    }
    
    private func loadCoverImage() {
        if let comic = entry.comic,
           let fileName = comic.coverBildName {
            coverImage = ImageManager.shared.loadImage(named: fileName)
        }
    }
    
    private func reloadCoverIfNeeded() {
        if let comic = entry.comic,
           let fileName = comic.coverBildName,
           coverImage == nil {
            coverImage = ImageManager.shared.loadImage(named: fileName)
        }
    }
    
    // MARK: - Context Menu
        
    @ViewBuilder
    private var contextMenuContent: some View {
        if entry.isPlaceholder {
            // Platzhalter-Optionen
            Button {
                showingEditSheet = true
            } label: {
                Label("Titel bearbeiten", systemImage: "pencil")
            }
            
            Button {
                showingAddComicSheet = true
            } label: {
                Label("Comic hinzufügen", systemImage: "plus.circle")
            }
            
            Divider()
            
            Button(role: .destructive) {
                deleteEntry()
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        } else {
            // Comic-Optionen
            Button {
                toggleReadStatus()
            } label: {
                if entry.comic?.gelesen == true {
                    Label("Als ungelesen markieren", systemImage: "book")
                } else {
                    Label("Als gelesen markieren", systemImage: "checkmark.circle")
                }
            }
            
            Divider()
            
            Button(role: .destructive) {
                deleteEntry()
            } label: {
                Label("Aus Reading Order entfernen", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleReadStatus() {
        guard let comic = entry.comic else { return }
        comic.gelesen.toggle()
        try? modelContext.save()
    }
    
    private func deleteEntry() {
        guard let liste = entry.liste else { return }
        
        let position = entry.position
        
        // Entry löschen
        modelContext.delete(entry)
        
        // Folgende Entries nach oben verschieben
        let affectedEntries = liste.readingOrderEntries.filter { $0.position > position }
        for entry in affectedEntries {
            entry.position -= 1
        }
        
        try? modelContext.save()
    }
}


// MARK: - Drop Delegate

struct DropViewDelegate: DropDelegate {
    let item: ReadingOrderEntry
    let liste: ComicListe
    let modelContext: ModelContext
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else {
            return false
        }
        
        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, error in
            guard let data = data as? Data,
                  let draggedIDString = String(data: data, encoding: .utf8),
                  let draggedID = UUID(uuidString: draggedIDString),
                  let draggedEntry = liste.readingOrderEntries.first(where: { $0.id == draggedID }),
                  draggedEntry.id != item.id else {
                return
            }
            
            DispatchQueue.main.async {
                moveEntry(draggedEntry, to: item)
            }
        }
        
        return true
    }
    
    private func moveEntry(_ draggedEntry: ReadingOrderEntry, to targetEntry: ReadingOrderEntry) {
        let oldPosition = draggedEntry.position
        let newPosition = targetEntry.position
        
        guard oldPosition != newPosition else { return }
        
        if oldPosition < newPosition {
            // Nach unten verschieben: Entries dazwischen nach oben
            let affectedEntries = liste.readingOrderEntries.filter {
                $0.position > oldPosition && $0.position <= newPosition
            }
            for entry in affectedEntries {
                entry.position -= 1
            }
        } else {
            // Nach oben verschieben: Entries dazwischen nach unten
            let affectedEntries = liste.readingOrderEntries.filter {
                $0.position >= newPosition && $0.position < oldPosition
            }
            for entry in affectedEntries {
                entry.position += 1
            }
        }
        
        draggedEntry.position = newPosition
        
        try? modelContext.save()
    }
}
