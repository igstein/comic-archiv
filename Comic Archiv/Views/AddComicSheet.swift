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
    @State private var genre = ""
    @State private var coverImage: NSImage?

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
                        ForEach(ReadStatus.allCases, id: \.self) { s in
                            Label(s.label, systemImage: s.icon).tag(s)
                        }
                    }
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { p in
                            Label(p.label, systemImage: p.icon).tag(p)
                        }
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
                    Button("Add") { addComic() }.disabled(title.isEmpty)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 500)
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
            readStatus: readStatus, priority: priority, genre: genre
        )
        if let image = coverImage { viewModel.setCoverImage(image, for: newComic) }
        viewModel.addComic(newComic, toList: targetList)
        viewModel.convertPlaceholdersToComic(newComic)
        dismiss()
    }
}
