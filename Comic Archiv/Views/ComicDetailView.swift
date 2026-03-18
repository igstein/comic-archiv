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

    @State private var title: String
    @State private var series: String
    @State private var author: String
    @State private var artist: String
    @State private var publisher: String
    @State private var issueNumber: String
    @State private var releaseDate: Date
    @State private var readStatus: ReadStatus
    @State private var priority: Priority
    @State private var format: ComicFormat
    @State private var genre: String
    @State private var notes: String
    @State private var rating: Double
    @State private var seriesLengthText: String
    @State private var coverImage: NSImage?
    @State private var showingDeleteAlert = false

    init(comic: Comic, viewModel: ComicViewModel, onDelete: @escaping () -> Void) {
        self.comic = comic
        self.viewModel = viewModel
        self.onDelete = onDelete
        _title            = State(initialValue: comic.title)
        _series           = State(initialValue: comic.series)
        _author           = State(initialValue: comic.author)
        _artist           = State(initialValue: comic.artist)
        _publisher        = State(initialValue: comic.publisher)
        _issueNumber      = State(initialValue: comic.issueNumber)
        _releaseDate      = State(initialValue: comic.releaseDate)
        _readStatus       = State(initialValue: comic.readStatus)
        _priority         = State(initialValue: comic.priority)
        _format           = State(initialValue: comic.format)
        _genre            = State(initialValue: comic.genre)
        _notes            = State(initialValue: comic.notes)
        _rating           = State(initialValue: comic.rating)
        _seriesLengthText = State(initialValue: comic.seriesLength.map(String.init) ?? "")
        if let fileName = comic.coverImageName {
            _coverImage = State(initialValue: ImageManager.shared.loadImage(named: fileName))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Comic Details") {
                    TextField("Title",          text: $title)
                    TextField("Series",         text: $series)
                    TextField("Issue / Volume", text: $issueNumber)
                    TextField("Author",         text: $author)
                    TextField("Artist",         text: $artist)
                    TextField("Publisher",      text: $publisher)
                    TextField("Genre",          text: $genre)
                    HStack {
                        Text("Series Length")
                        Spacer()
                        TextField("Unknown", text: $seriesLengthText)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .onChange(of: seriesLengthText) { _, val in
                                seriesLengthText = val.filter(\.isNumber)
                            }
                    }
                }

                Section("Status") {
                    Picker("Read Status", selection: $readStatus) {
                        ForEach(ReadStatus.allCases, id: \.self) { s in
                            Label(s.label, systemImage: s.icon).tag(s)
                        }
                    }
                    Picker("Format", selection: $format) {
                        ForEach(ComicFormat.allCases, id: \.self) { f in
                            Label(f.label, systemImage: f.icon).tag(f)
                        }
                    }
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { p in
                            Label(p.label, systemImage: p.icon).tag(p)
                        }
                    }
                    HStack {
                        Text("Rating")
                        Spacer()
                        StarRatingPicker(rating: $rating)
                    }
                    DatePicker("Release Date", selection: $releaseDate, displayedComponents: .date)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

                Section("Cover Image") {
                    VStack(spacing: 12) {
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
                                        .font(.system(size: 60)).foregroundStyle(.gray)
                                    Text("No cover image")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        HStack {
                            Button { selectImage() } label: {
                                Label(coverImage == nil ? "Add Cover" : "Change Cover", systemImage: "photo")
                            }
                            if coverImage != nil {
                                Button(role: .destructive) { coverImage = nil } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        Button(role: .destructive) { showingDeleteAlert = true } label: {
                            Label("Delete Comic", systemImage: "trash").font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Comic")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { saveChanges() } }
            }
            .alert("Delete Comic?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) { deleteComic() }
            } message: {
                Text("Delete '\(comic.title)'? This cannot be undone.")
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }

    private func selectImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .heic, .gif, .bmp, .tiff]
        panel.message = "Choose a cover image"
        panel.begin { response in
            guard response == .OK, let url = panel.url,
                  let image = NSImage(contentsOf: url) else { return }
            coverImage = image
        }
    }

    private func saveChanges() {
        comic.title        = title
        comic.series       = series
        comic.author       = author
        comic.artist       = artist
        comic.publisher    = publisher
        comic.issueNumber  = issueNumber
        comic.releaseDate  = releaseDate
        comic.genre        = genre
        comic.notes        = notes
        comic.priority     = priority
        comic.format       = format
        comic.rating       = rating
        comic.seriesLength = seriesLengthText.isEmpty ? nil : Int(seriesLengthText)

        if readStatus == .finished && comic.readStatus != .finished {
            comic.lastReadAt = Date()
        }
        comic.readStatus = readStatus

        if let image = coverImage {
            viewModel.setCoverImage(image, for: comic)
        } else if comic.coverImageName != nil {
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
