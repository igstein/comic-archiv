//
//  ReadingOrderContentView.swift
//  Comic Archiv
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ReadingOrderContentView: View {
    let list: ComicList
    let viewModel: ComicViewModel?

    @State private var showingAddEntry = false
    @State private var showingDuplicateAlert = false
    @State private var isDropTarget = false
    @Environment(\.modelContext) private var modelContext

    @Query private var allComics: [Comic]

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()

            if list.readingOrderEntries.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(list.sortedReadingOrderEntries, id: \.id) { entry in
                            ReadingOrderEntryRow(entry: entry, viewModel: viewModel)
                                .onDrop(of: [.text], delegate: DropViewDelegate(
                                    item: entry, list: list, modelContext: modelContext
                                ))
                            if entry.id != list.sortedReadingOrderEntries.last?.id {
                                Divider().padding(.leading, 60)
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
            AddReadingOrderEntrySheet(list: list, viewModel: viewModel)
        }
        .alert("Already in Reading Order", isPresented: $showingDuplicateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This comic is already in this reading order.")
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: list.icon ?? "list.number")
                .font(.title)
                .foregroundStyle(.orange)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(list.name)
                    .font(.title2)
                    .fontWeight(.semibold)

                if let progress = list.readingProgress {
                    HStack(spacing: 12) {
                        Label("\(progress.read)/\(progress.total) read", systemImage: "checkmark.circle")
                            .font(.subheadline).foregroundStyle(.secondary)
                        if progress.toBuy > 0 {
                            Label("\(progress.toBuy) to buy", systemImage: "cart")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()

            Button { showingAddEntry = true } label: {
                Label("Add Entry", systemImage: "plus.circle.fill")
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
                .font(.system(size: 48)).foregroundStyle(.secondary)

            Text("No Entries")
                .font(.title3).fontWeight(.medium)

            Text("Add comics or placeholders to build your reading order.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).frame(maxWidth: 300)

            Button { showingAddEntry = true } label: {
                Label("Add First Entry", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Drop Handler

    private func handleComicDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let uuidString = String(data: data, encoding: .utf8),
                  let uuid = UUID(uuidString: uuidString),
                  let comic = allComics.first(where: { $0.id == uuid }),
                  let viewModel else { return }
            DispatchQueue.main.async {
                if !viewModel.addComicToReadingOrder(comic, readingOrder: list) {
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
            Text("\(entry.position).")
                .font(.headline).foregroundStyle(.secondary)
                .frame(width: 30, alignment: .trailing)

            Image(systemName: statusIcon)
                .font(.title3).foregroundStyle(statusColor)
                .frame(width: 24)

            coverView.frame(width: 40, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayName).font(.body).fontWeight(.medium)

                if let comic = entry.comic {
                    HStack(spacing: 8) {
                        if !comic.author.isEmpty {
                            Text(comic.author).font(.caption).foregroundStyle(.secondary)
                        }
                        if !comic.publisher.isEmpty {
                            Image(systemName: "circle.fill").font(.system(size: 4)).foregroundStyle(.tertiary)
                            Text(comic.publisher).font(.caption).foregroundStyle(.secondary)
                        }
                        if !comic.issueNumber.isEmpty {
                            Image(systemName: "circle.fill").font(.system(size: 4)).foregroundStyle(.tertiary)
                            Text("#\(comic.issueNumber)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Not in collection yet").font(.caption).foregroundStyle(.orange)
                }
            }

            Spacer()
            statusBadge

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary).font(.body)
                .opacity(isHovering ? 1.0 : 0.0)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isDragging ? Color.accentColor.opacity(0.1)
                      : (isHovering ? Color.secondary.opacity(0.05) : Color.clear))
        )
        .opacity(isDragging ? 0.5 : 1.0)
        .onHover { isHovering = $0 }
        .onAppear { loadCoverImage() }
        .onChange(of: entry.comic?.coverImageName) { _, newValue in
            if newValue != nil { loadCoverImage() }
        }
        .contextMenu { contextMenuContent }
        .sheet(isPresented: $showingEditSheet) { EditPlaceholderSheet(entry: entry) }
        .sheet(isPresented: $showingAddComicSheet) {
            if let viewModel { AddComicSheetForPlaceholder(entry: entry, viewModel: viewModel) }
        }
        .contentShape(Rectangle())
        .onDrag {
            isDragging = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isDragging = false }
            return NSItemProvider(object: entry.id.uuidString as NSString)
        }
    }

    private var statusIcon: String {
        if entry.isPlaceholder                       { return "cart" }
        switch entry.comic?.readStatus {
        case .finished:  return "checkmark.circle.fill"
        case .reading:   return "book"
        case .paused:    return "pause.circle"
        case .abandoned: return "xmark.circle"
        default:         return "book.closed"
        }
    }

    private var statusColor: Color {
        if entry.isPlaceholder                       { return .orange }
        switch entry.comic?.readStatus {
        case .finished:  return .green
        case .reading:   return .blue
        case .paused:    return .orange
        case .abandoned: return .red
        default:         return .secondary
        }
    }

    private var statusBadge: some View {
        Group {
            if entry.isPlaceholder {
                Text("To Buy")
                    .font(.caption).fontWeight(.medium).foregroundStyle(.orange)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(Color.orange.opacity(0.15)))
            } else if entry.comic?.readStatus == .finished {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.title3)
            } else if let status = entry.comic?.readStatus, status != .unread {
                Text(status.label)
                    .font(.caption).fontWeight(.medium).foregroundStyle(statusColor)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(statusColor.opacity(0.15)))
            }
        }
    }

    @ViewBuilder
    private var coverView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2))
            if let image = coverImage {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 60).clipShape(RoundedRectangle(cornerRadius: 4))
            } else if entry.isPlaceholder {
                Image(systemName: "cart").font(.title3).foregroundStyle(.gray)
            } else {
                Image(systemName: "book.closed").font(.title3).foregroundStyle(.gray)
            }
        }
    }

    private func loadCoverImage() {
        if let comic = entry.comic, let fileName = comic.coverImageName {
            coverImage = ImageManager.shared.loadImage(named: fileName)
        }
    }

    @ViewBuilder
    private var contextMenuContent: some View {
        if entry.isPlaceholder {
            Button { showingEditSheet = true }     label: { Label("Edit Title", systemImage: "pencil") }
            Button { showingAddComicSheet = true } label: { Label("Add Comic", systemImage: "plus.circle") }
            Divider()
            Button(role: .destructive) { deleteEntry() } label: { Label("Delete", systemImage: "trash") }
        } else {
            Menu("Set Status") {
                Button { setStatus(.unread) }    label: { Label("Unread",    systemImage: "book.closed") }
                Button { setStatus(.reading) }   label: { Label("Reading",   systemImage: "book") }
                Button { setStatus(.paused) }    label: { Label("Paused",    systemImage: "pause.circle") }
                Button { setStatus(.finished) }  label: { Label("Finished",  systemImage: "checkmark.circle") }
                Button { setStatus(.abandoned) } label: { Label("Abandoned", systemImage: "xmark.circle") }
            }
            Divider()
            Button(role: .destructive) { deleteEntry() } label: {
                Label("Remove from Reading Order", systemImage: "trash")
            }
        }
    }

    private func setStatus(_ status: ReadStatus) {
        guard let comic = entry.comic else { return }
        if status == .finished { comic.lastReadAt = Date() }
        comic.readStatus = status
        try? modelContext.save()
    }

    private func deleteEntry() {
        guard let list = entry.list else { return }
        let position = entry.position
        modelContext.delete(entry)
        for e in list.readingOrderEntries where e.position > position { e.position -= 1 }
        try? modelContext.save()
    }
}

// MARK: - Drop Delegate

struct DropViewDelegate: DropDelegate {
    let item: ReadingOrderEntry
    let list: ComicList
    let modelContext: ModelContext

    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }
        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, _ in
            guard let data = data as? Data,
                  let draggedIDString = String(data: data, encoding: .utf8),
                  let draggedID = UUID(uuidString: draggedIDString),
                  let draggedEntry = list.readingOrderEntries.first(where: { $0.id == draggedID }),
                  draggedEntry.id != item.id else { return }
            DispatchQueue.main.async { moveEntry(draggedEntry, to: item) }
        }
        return true
    }

    private func moveEntry(_ draggedEntry: ReadingOrderEntry, to targetEntry: ReadingOrderEntry) {
        let oldPosition = draggedEntry.position
        let newPosition = targetEntry.position
        guard oldPosition != newPosition else { return }

        if oldPosition < newPosition {
            for e in list.readingOrderEntries where e.position > oldPosition && e.position <= newPosition {
                e.position -= 1
            }
        } else {
            for e in list.readingOrderEntries where e.position >= newPosition && e.position < oldPosition {
                e.position += 1
            }
        }
        draggedEntry.position = newPosition
        try? modelContext.save()
    }
}
