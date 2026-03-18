//
//  MALImportView.swift
//  Comic Archiv
//

import SwiftUI
import SwiftData

// MARK: - MAL Import View

struct MALImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let viewModel: ComicViewModel

    @State private var phase: ImportPhase = .idle
    @State private var isAuthenticated = false
    @State private var entries:   [MALMangaEntry] = []
    @State private var selected:  Set<Int>        = []
    @State private var errorText: String?
    @State private var importedComics = 0

    enum ImportPhase {
        case idle, authorizing, fetching, preview, importing, done
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Import from MyAnimeList")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .disabled(phase == .importing)
                    }
                    if phase == .preview {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Import \(selected.count)") { startImport() }
                                .disabled(selected.isEmpty)
                        }
                    }
                }
        }
        .frame(minWidth: 560, minHeight: 480)
    }

    // MARK: - Phase Views

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .idle:        idleView
        case .authorizing: progressView("Waiting for MyAnimeList login…")
        case .fetching:    progressView("Fetching manga list…")
        case .preview:     previewView
        case .importing:   progressView("Importing comics…")
        case .done:        doneView
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 24) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 64)).foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("Import Your MAL Manga List")
                    .font(.title2).fontWeight(.semibold)
                Text(isAuthenticated
                     ? "Fetch your latest manga list from MyAnimeList. Already imported volumes will be skipped."
                     : "This will open MyAnimeList in your browser to authorize Comic Archiv, then import your manga as comics.")
                    .font(.body).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }

            if let error = errorText {
                Text(error)
                    .font(.callout).foregroundStyle(.red)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                if isAuthenticated {
                    Button {
                        Task { await fetchList() }
                    } label: {
                        Label("Fetch Latest from MAL", systemImage: "arrow.clockwise")
                            .frame(maxWidth: 280)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Disconnect") {
                        Task {
                            await MALImportService.shared.logout()
                            isAuthenticated = false
                        }
                    }
                    .font(.subheadline).foregroundStyle(.secondary)
                } else {
                    Button {
                        startAuthorize()
                    } label: {
                        Label("Connect to MyAnimeList", systemImage: "arrow.up.right.square")
                            .frame(maxWidth: 280)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Text("You'll be redirected to myanimelist.net to log in.\nComic Archiv never stores your MAL password.")
                        .font(.caption).foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .task {
            isAuthenticated = await MALImportService.shared.isAuthenticated
        }
    }

    // MARK: - Progress

    private func progressView(_ message: String) -> some View {
        VStack(spacing: 16) {
            ProgressView()
            Text(message).font(.body).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Preview

    private var previewView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(entries.count) manga found")
                    .font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Button(selected.count == entries.count ? "Deselect All" : "Select All") {
                    if selected.count == entries.count {
                        selected.removeAll()
                    } else {
                        selected = Set(entries.map(\.id))
                    }
                }
                .font(.subheadline)
            }
            .padding(.horizontal, 20).padding(.vertical, 10)

            Divider()

            List(entries, selection: $selected) { entry in
                MALEntryRow(entry: entry)
                    .tag(entry.id)
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Done

    private var doneView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64)).foregroundStyle(.green)
            Text("Import Complete")
                .font(.title2).fontWeight(.semibold)
            Text(importedComics == 0 ? "Everything is already up to date." : "\(importedComics) new volumes added to your collection.")
                .font(.body).foregroundStyle(.secondary)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func startAuthorize() {
        errorText = nil
        phase = .authorizing
        Task {
            do {
                try await MALImportService.shared.authorize()
                await fetchList()
            } catch {
                await MainActor.run {
                    errorText = error.localizedDescription
                    phase     = .idle
                }
            }
        }
    }

    private func fetchList() async {
        await MainActor.run { phase = .fetching }
        do {
            let list = try await MALImportService.shared.fetchMangaList()
            await MainActor.run {
                entries  = list
                selected = Set(list.map(\.id))
                phase    = .preview
            }
        } catch {
            await MainActor.run {
                errorText = error.localizedDescription
                phase     = .idle
            }
        }
    }

    private func startImport() {
        phase = .importing
        Task {
            let toImport = entries.filter { selected.contains($0.id) }
            var comicCount = 0

            let descriptor = FetchDescriptor<ComicList>(predicate: #Predicate { $0.isMainCollection })
            let mainCollection = try? modelContext.fetch(descriptor).first

            // Build a set of existing title+issueNumber pairs for duplicate detection
            let existingComics = (try? modelContext.fetch(FetchDescriptor<Comic>())) ?? []
            let existingKeys = Set(existingComics.map { "\($0.title)||||\($0.issueNumber)" })

            let defaultDate: Date = {
                var c = DateComponents(); c.year = 1900; c.month = 1; c.day = 1
                return Calendar.current.date(from: c) ?? Date()
            }()

            for entry in toImport {
                let node    = entry.node
                let numRead = entry.listStatus?.numVolumesRead ?? 0
                guard numRead > 0 else { continue }

                let authors = node.authors?
                    .filter { $0.role?.lowercased().contains("story") == true }
                    .map(\.node.fullName) ?? []
                let artists = node.authors?
                    .filter { $0.role?.lowercased().contains("art") == true }
                    .map(\.node.fullName) ?? []
                let genres  = node.genres?.prefix(3).map(\.name).joined(separator: ", ") ?? ""

                var releaseDate: Date? = nil
                if let dateStr = node.startDate {
                    let f = DateFormatter()
                    for fmt in ["yyyy-MM-dd", "yyyy-MM", "yyyy"] {
                        f.dateFormat = fmt
                        if let d = f.date(from: dateStr) { releaseDate = d; break }
                    }
                }

                // Download cover once, reuse for all volumes
                var coverImage: NSImage? = nil
                if let urlStr = node.mainPicture?.large ?? node.mainPicture?.medium,
                   let url = URL(string: urlStr),
                   let (data, _) = try? await URLSession.shared.data(from: url) {
                    coverImage = NSImage(data: data)
                }

                // One Comic per volume read — skip already imported volumes
                for vol in 1...numRead {
                    let issueNumber = "Vol. \(vol)"
                    let key = "\(node.title)||||\(issueNumber)"
                    guard !existingKeys.contains(key) else { continue }

                    let volStatus: ReadStatus = (vol < numRead) ? .finished
                        : (entry.listStatus?.readStatus ?? .finished)

                    let comic = Comic(
                        title:        node.title,
                        author:       authors.joined(separator: ", "),
                        artist:       artists.joined(separator: ", "),
                        publisher:    "",
                        releaseDate:  releaseDate ?? defaultDate,
                        issueNumber:  issueNumber,
                        readStatus:   volStatus,
                        priority:     .medium,
                        genre:        genres,
                        series:       node.title,
                        seriesLength: node.numVolumes
                    )
                    if let image = coverImage { viewModel.setCoverImage(image, for: comic) }
                    if let list = mainCollection { viewModel.addComic(comic, toList: list) }
                    else { modelContext.insert(comic) }
                    comicCount += 1
                }
            }

            try? modelContext.save()
            await MainActor.run {
                importedComics = comicCount
                phase          = .done
            }
        }
    }
}

// MARK: - Entry Row

private struct MALEntryRow: View {
    let entry: MALMangaEntry

    var body: some View {
        HStack(spacing: 10) {
            AsyncImage(url: entry.node.mainPicture?.medium.flatMap(URL.init)) { phase in
                if case .success(let image) = phase {
                    image.resizable().aspectRatio(contentMode: .fill)
                        .frame(width: 30, height: 45)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                } else {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 30, height: 45)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.node.title)
                    .font(.headline).lineLimit(1)
                HStack(spacing: 8) {
                    if let status = entry.listStatus?.status {
                        Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption2).fontWeight(.medium)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(statusColor(status).opacity(0.15)))
                            .foregroundStyle(statusColor(status))
                    }
                    if let vols = entry.node.numVolumes {
                        Text("\(vols) vols").font(.caption).foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "completed":     return .green
        case "reading":       return .blue
        case "on_hold":       return .orange
        case "dropped":       return .red
        default:              return .secondary
        }
    }
}
