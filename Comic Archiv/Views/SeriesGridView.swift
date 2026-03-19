//
//  SeriesGridView.swift
//  Comic Archiv
//

import SwiftUI

// MARK: - Series Group Model

struct SeriesGroup: Identifiable {
    let name: String
    let comics: [Comic]

    var id: String { name }

    var firstComic: Comic? {
        comics.sorted { volumeNumber($0.issueNumber) < volumeNumber($1.issueNumber) }.first
    }

    var readCount:  Int { comics.filter { $0.readStatus == .finished }.count }
    var totalCount: Int { comics.count }

    private func volumeNumber(_ issueNumber: String) -> Int {
        let digits = issueNumber.filter(\.isNumber)
        return Int(digits) ?? 0
    }
}

// MARK: - Series Grid View

struct SeriesGridView: View {
    let comics: [Comic]
    let viewModel: ComicViewModel?
    let onSelectSeries: (String) -> Void
    var onAddComic: (() -> Void)?

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 24)]

    private var seriesGroups: [SeriesGroup] {
        let grouped = Dictionary(grouping: comics.filter { !$0.series.isEmpty }, by: \.series)
        return grouped.map { SeriesGroup(name: $0.key, comics: $0.value) }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    private var uncategorized: [Comic] {
        comics.filter { $0.series.isEmpty }
            .sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
    }

    @State private var selectedComic: Comic?

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(seriesGroups) { group in
                    SeriesCardView(group: group)
                        .onTapGesture { onSelectSeries(group.name) }
                }
            }
            .padding(20)

            if !uncategorized.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("No Series Set")
                        .font(.title3).fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)

                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(uncategorized) { comic in
                            ComicCardView(comic: comic) { selectedComic = comic }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
        }
        .toolbar {
            if let onAddComic {
                ToolbarItem(placement: .automatic) {
                    Button { onAddComic() } label: {
                        Label("Add Comic", systemImage: "plus")
                    }
                    .keyboardShortcut("n", modifiers: .command)
                    .help("Add new comic (⌘N)")
                }
            }
        }
        .sheet(item: $selectedComic) { comic in
            if let viewModel {
                ComicDetailView(comic: comic, viewModel: viewModel) { selectedComic = nil }
            }
        }
    }
}

// MARK: - Series Card View

struct SeriesCardView: View {
    let group: SeriesGroup

    @State private var coverImage: NSImage?
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover
            ZStack(alignment: .bottomLeading) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(2/3, contentMode: .fit)

                    if let image = coverImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(2/3, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray)
                    }
                }

                // Volume count badge
                Text("\(group.totalCount) vol\(group.totalCount == 1 ? "" : "s")")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Capsule().fill(Color.black.opacity(0.6)))
                    .padding(6)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                // Read progress
                if group.readCount > 0 {
                    HStack(spacing: 4) {
                        ProgressView(value: Double(group.readCount), total: Double(group.totalCount))
                            .progressViewStyle(.linear)
                            .tint(.green)
                        Text("\(group.readCount)/\(group.totalCount)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize()
                    }
                }
            }
        }
        .padding(8)
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(
            color: .black.opacity(isHovering ? 0.15 : 0.1),
            radius: isHovering ? 8 : 4,
            y: isHovering ? 4 : 2
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { isHovering = $0 }
        .onAppear { loadCover() }
    }

    private func loadCover() {
        guard let comic = group.firstComic,
              let fileName = comic.coverImageName else { return }
        coverImage = ImageManager.shared.loadImage(named: fileName)
    }
}
