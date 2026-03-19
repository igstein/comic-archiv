//
//  AddComicSheet.swift
//  Comic Archiv
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AddComicSheet: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: ComicViewModel
    let targetList: ComicList?

    @State private var title = ""
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
    @State private var format: ComicFormat = .physical
    @State private var genre = ""
    @State private var series = ""
    @State private var seriesLengthText = ""
    @State private var rating: Double = 0.0
    @State private var coverImage: NSImage?

    var body: some View {
        NavigationStack {
            Form {
                ComicSearchSection { result in applyResult(result) }

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
                        if seriesLengthText.isEmpty {
                            Text("Unknown").foregroundStyle(.tertiary)
                        } else {
                            TextField("", text: $seriesLengthText)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 50)
                                .onChange(of: seriesLengthText) { _, val in
                                    seriesLengthText = val.filter(\.isNumber)
                                }
                        }
                        Stepper("", value: Binding(
                            get: { Int(seriesLengthText) ?? 0 },
                            set: { seriesLengthText = $0 > 0 ? String($0) : "" }
                        ), in: 0...9999)
                        .labelsHidden()
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

                Section("Cover Image") {
                    VStack(spacing: 12) {
                        if let image = coverImage {
                            Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200).clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2)).frame(height: 200)
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
                                Button(role: .destructive) { coverImage = nil } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Comic")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addComic() }.disabled(title.isEmpty || series.isEmpty)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 500)
    }

    private func applyResult(_ result: ComicSearchResult) {
        title       = result.title
        series      = result.title
        publisher   = result.publisher
        issueNumber = result.issueNumber
        if !result.author.isEmpty { author = result.author }
        if !result.artist.isEmpty { artist = result.artist }
        if !result.genre.isEmpty  { genre  = result.genre  }
        if let date = result.releaseDate { releaseDate = date }

        if let url = result.coverURL {
            Task { @MainActor in
                if let (data, _) = try? await URLSession.shared.data(from: url),
                   let image = NSImage(data: data) { coverImage = image }
            }
        }
        if case .comicVine = result.source {
            Task { @MainActor in
                let full = await ComicSearchService.shared.enrichComicVineResult(result)
                if !full.author.isEmpty { author = full.author }
                if !full.artist.isEmpty { artist = full.artist }
                if !full.genre.isEmpty  { genre  = full.genre  }
            }
        }
    }

    private func selectImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false; panel.canChooseDirectories = false
        panel.canChooseFiles = true; panel.allowedContentTypes = [.png, .jpeg, .heic, .gif, .bmp, .tiff]
        panel.message = "Choose a cover image"
        panel.begin { response in
            guard response == .OK, let url = panel.url,
                  let image = NSImage(contentsOf: url) else { return }
            coverImage = image
        }
    }

    private func addComic() {
        let newComic = Comic(
            title: title, author: author, artist: artist, publisher: publisher,
            releaseDate: releaseDate, issueNumber: issueNumber,
            readStatus: readStatus, priority: priority, genre: genre,
            series: series,
            seriesLength: seriesLengthText.isEmpty ? nil : Int(seriesLengthText),
            rating: rating, format: format
        )
        if let image = coverImage { viewModel.setCoverImage(image, for: newComic) }
        viewModel.addComic(newComic, toList: targetList)
        viewModel.convertPlaceholdersToComic(newComic)
        dismiss()
    }
}
