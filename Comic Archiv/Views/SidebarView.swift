//
//  SidebarView.swift
//  Comic Archiv
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SidebarView: View {
    let lists: [ComicList]
    let comics: [Comic]
    @Binding var selectedList: ComicList?
    let viewModel: ComicViewModel?

    @State private var showingAddList = false
    @State private var showingAddReadingOrder = false
    @State private var listToEdit: ComicList?
    @State private var listToDelete: ComicList?
    @State private var showingDeleteAlert = false
    @State private var dropTargetList: ComicList?

    private var mainCollection: ComicList? { lists.first { $0.isMainCollection } }
    private var wishlist: ComicList?       { lists.first { $0.isWishlist } }

    private var regularLists: [ComicList] {
        lists.filter { !$0.isReadingOrder && !$0.isMainCollection && !$0.isWishlist }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    private var readingOrders: [ComicList] {
        lists.filter { $0.isReadingOrder }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        List(selection: $selectedList) {
            Section("Lists") {
                if let mainCollection {
                    ListRowView(
                        list: mainCollection,
                        isDropTarget: dropTargetList?.id == mainCollection.id,
                        onEdit: { listToEdit = mainCollection },
                        onDelete: { }
                    )
                    .tag(mainCollection)
                    .onDrop(of: [UTType.text], isTargeted: createBinding(for: mainCollection)) { providers in
                        handleDrop(providers: providers, toList: mainCollection)
                    }
                }

                if let wishlist {
                    WishlistSidebarRowView(list: wishlist).tag(wishlist)
                }

                ForEach(regularLists) { list in
                    ListRowView(
                        list: list,
                        isDropTarget: dropTargetList?.id == list.id,
                        onEdit: { listToEdit = list },
                        onDelete: { listToDelete = list; showingDeleteAlert = true }
                    )
                    .tag(list)
                    .onDrop(of: [UTType.text], isTargeted: createBinding(for: list)) { providers in
                        handleDrop(providers: providers, toList: list)
                    }
                }
            }

            Section("Reading Orders") {
                ForEach(readingOrders) { list in
                    ReadingOrderRowView(
                        list: list,
                        onEdit: { listToEdit = list },
                        onDelete: { listToDelete = list; showingDeleteAlert = true },
                        viewModel: viewModel,
                        allComics: comics
                    )
                    .tag(list)
                }
            }
        }
        .navigationTitle("Comic Archiv")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { showingAddList = true } label: {
                    Label("New List", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button { showingAddReadingOrder = true } label: {
                    Label("New Reading Order", systemImage: "list.number")
                }
            }
        }
        .sheet(isPresented: $showingAddList) {
            if let viewModel { AddListSheet(viewModel: viewModel) }
        }
        .sheet(isPresented: $showingAddReadingOrder) {
            if let viewModel { AddReadingOrderSheet(viewModel: viewModel) }
        }
        .sheet(item: $listToEdit) { list in
            if let viewModel { EditListSheet(list: list, viewModel: viewModel) }
        }
        .alert("Delete List?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let list = listToDelete { deleteList(list) }
            }
        } message: {
            if let list = listToDelete {
                Text(list.isReadingOrder
                     ? "Delete the reading order '\(list.name)'? Your comics will not be affected."
                     : "Delete the list '\(list.name)'? Your comics will not be affected.")
            }
        }
    }

    private func createBinding(for list: ComicList) -> Binding<Bool> {
        Binding(
            get: { dropTargetList?.id == list.id },
            set: { isTargeted in
                if isTargeted { dropTargetList = list }
                else if dropTargetList?.id == list.id { dropTargetList = nil }
            }
        )
    }

    private func handleDrop(providers: [NSItemProvider], toList list: ComicList) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let uuidString = String(data: data, encoding: .utf8),
                  let uuid = UUID(uuidString: uuidString),
                  let comic = comics.first(where: { $0.id == uuid }),
                  let viewModel else { return }
            DispatchQueue.main.async {
                viewModel.addComicToList(comic, list: list)
                dropTargetList = nil
            }
        }
        return true
    }

    private func deleteList(_ list: ComicList) {
        if selectedList?.id == list.id { selectedList = lists.first }
        viewModel?.deleteList(list)
    }
}

// MARK: - List Row

struct ListRowView: View {
    let list: ComicList
    let isDropTarget: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            if let iconName = list.icon {
                Image(systemName: iconName)
                    .foregroundStyle(list.isMainCollection ? .blue : .secondary)
                    .font(.body)
                    .frame(width: 20)
            }
            Text(list.name)
                .fontWeight(list.isMainCollection ? .semibold : .regular)
            Spacer()
            Text("\(list.comics.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.secondary.opacity(0.15)))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isDropTarget ? Color.accentColor.opacity(0.2) : Color.clear)
        )
        .contentShape(Rectangle())
        .contextMenu {
            Button { onEdit() } label: { Label("Rename", systemImage: "pencil") }
            if !list.isMainCollection && !list.isWishlist {
                Divider()
                Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
            }
        }
    }
}

// MARK: - Reading Order Row

struct ReadingOrderRowView: View {
    let list: ComicList
    let onEdit: () -> Void
    let onDelete: () -> Void
    let viewModel: ComicViewModel?
    let allComics: [Comic]

    @State private var isDropTarget = false
    @State private var showingDuplicateAlert = false

    private var progressText: String {
        if let p = list.readingProgress, p.total > 0 {
            return "\(p.read)/\(p.total) read"
        }
        return ""
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: list.icon ?? "list.number")
                .foregroundStyle(.orange)
                .font(.body)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(list.name).fontWeight(.regular)
                if !progressText.isEmpty {
                    Text(progressText).font(.caption2).foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("\(list.readingOrderEntries.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.orange.opacity(0.15)))
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
            Button { onEdit() } label: { Label("Rename", systemImage: "pencil") }
            Divider()
            Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
        }
        .alert("Already in Reading Order", isPresented: $showingDuplicateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This comic is already in this reading order.")
        }
    }

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

// MARK: - Wishlist Sidebar Row

struct WishlistSidebarRowView: View {
    let list: ComicList

    @Query(filter: #Predicate<PlaceholderComic> { $0.inWishlist == true })
    private var placeholders: [PlaceholderComic]

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: list.icon ?? "cart")
                .foregroundStyle(.orange)
                .font(.body)
                .frame(width: 20)
            Text(list.name)
            Spacer()
            Text("\(placeholders.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.orange.opacity(0.15)))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
}
