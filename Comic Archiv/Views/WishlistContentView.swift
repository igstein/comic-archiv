//
//  WishlistContentView.swift
//  Comic Archiv
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct WishlistContentView: View {
    let list: ComicList
    let viewModel: ComicViewModel?

    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<PlaceholderComic> { $0.inWishlist == true }, sort: \PlaceholderComic.name)
    private var placeholders: [PlaceholderComic]

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 24)]

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            if placeholders.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(placeholders) { placeholder in
                            PlaceholderCardView(placeholder: placeholder, viewModel: viewModel)
                        }
                    }
                    .padding(20)
                }
            }
        }
    }

    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "cart")
                .font(.title).foregroundStyle(.orange).frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text("Wishlist").font(.title2).fontWeight(.semibold)
                Text("\(placeholders.count) comics to buy").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 24).padding(.vertical, 16)
        .background(Color(.windowBackgroundColor))
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart").font(.system(size: 64)).foregroundStyle(.secondary)
            Text("Wishlist is Empty").font(.title2).fontWeight(.semibold)
            Text("Placeholders from reading orders appear here automatically.")
                .font(.body).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
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
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.15)).aspectRatio(2/3, contentMode: .fit)
                VStack(spacing: 8) {
                    Image(systemName: "cart").font(.system(size: 40)).foregroundStyle(.orange)
                    Text("To Buy").font(.caption).fontWeight(.medium).foregroundStyle(.orange)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(placeholder.name).font(.headline).lineLimit(2).foregroundStyle(.primary)
                let count = placeholder.readingOrderEntries.count
                if count > 0 {
                    Text("In \(count) reading order\(count == 1 ? "" : "s")")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(isHovering ? 0.15 : 0.1), radius: isHovering ? 8 : 4, y: isHovering ? 4 : 2)
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { isHovering = $0 }
        .contextMenu {
            Button { showingAddComicSheet = true } label: { Label("Add to Collection", systemImage: "plus.circle") }
            Divider()
            Button(role: .destructive) { deletePlaceholder() } label: { Label("Remove from Wishlist", systemImage: "trash") }
        }
        .sheet(isPresented: $showingAddComicSheet) {
            if let viewModel { AddComicSheetFromWishlist(placeholder: placeholder, viewModel: viewModel) }
        }
    }

    private func deletePlaceholder() {
        for entry in placeholder.readingOrderEntries { modelContext.delete(entry) }
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

    @State private var title: String
    @State private var author = ""
    @State private var artist = ""
    @State private var publisher = ""
    @State private var issueNumber = ""
    @State private var releaseDate: Date = {
        var c = DateComponents(); c.year = 1900; c.month = 1; c.day = 1
        return Calendar.current.date(from: c) ?? Date()
    }()
    @State private var readStatus: ReadStatus = .unread
    @State private var priority: Priority = .medium
    @State private var genre = ""
    @State private var coverImage: NSImage?

    init(placeholder: PlaceholderComic, viewModel: ComicViewModel) {
        self.placeholder = placeholder
        self.viewModel = viewModel
        self._title = State(initialValue: placeholder.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Comic Details") {
                    TextField("Title",          text: $title)
                    TextField("Author",         text: $author)
                    TextField("Artist",         text: $artist)
                    TextField("Publisher",      text: $publisher)
                    TextField("Issue / Volume", text: $issueNumber)
                    TextField("Genre",          text: $genre)
                }
                Section("Status") {
                    Picker("Read Status", selection: $readStatus) {
                        ForEach(ReadStatus.allCases, id: \.self) { s in Label(s.label, systemImage: s.icon).tag(s) }
                    }
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { p in Label(p.label, systemImage: p.icon).tag(p) }
                    }
                    DatePicker("Release Date", selection: $releaseDate, displayedComponents: .date)
                }
                Section("Cover Image") { coverSection }
            }
            .formStyle(.grouped)
            .navigationTitle("Add to Collection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addComic() }.disabled(title.isEmpty)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 500)
    }

    private var coverSection: some View {
        VStack(spacing: 12) {
            if let image = coverImage {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200).clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2)).frame(height: 200)
                    VStack {
                        Image(systemName: "photo").font(.system(size: 40)).foregroundStyle(.gray)
                        Text("Optional").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            HStack {
                Button { selectImage() } label: {
                    Label(coverImage == nil ? "Add Cover" : "Change Cover", systemImage: "photo")
                }
                if coverImage != nil {
                    Button(role: .destructive) { coverImage = nil } label: { Label("Remove", systemImage: "trash") }
                }
            }
        }
    }

    private func selectImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false; panel.canChooseDirectories = false
        panel.canChooseFiles = true; panel.allowedContentTypes = [.png, .jpeg, .heic, .gif, .bmp, .tiff]
        panel.message = "Choose a cover image"
        panel.begin { response in
            guard response == .OK, let url = panel.url, let image = NSImage(contentsOf: url) else { return }
            coverImage = image
        }
    }

    private func addComic() {
        let newComic = Comic(title: title, author: author, artist: artist, publisher: publisher,
                            releaseDate: releaseDate, issueNumber: issueNumber,
                            readStatus: readStatus, priority: priority, genre: genre)
        if let image = coverImage { viewModel.setCoverImage(image, for: newComic) }

        let descriptor = FetchDescriptor<ComicList>(predicate: #Predicate { $0.isMainCollection })
        if let mainCollection = try? modelContext.fetch(descriptor).first {
            viewModel.addComic(newComic, toList: mainCollection)
        } else {
            modelContext.insert(newComic)
        }
        viewModel.convertPlaceholdersToComic(newComic)
        dismiss()
    }
}
