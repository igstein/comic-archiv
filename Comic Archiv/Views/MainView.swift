//
//  MainView.swift
//  Comic Archiv
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var comics: [Comic]
    @Query private var lists: [ComicList]

    @State private var selectedList: ComicList?
    @State private var showingAddComic = false
    @State private var viewModel: ComicViewModel?
    @State private var sortOrder: SortOrder = .title
    @State private var searchText = ""
    @State private var readFilter: ReadFilter = .all
    @State private var selectedComicFromSuggestion: Comic?
    @State private var showingMALImport = false
    @State private var selectedSeries: String?
    @State private var xlsxImportRows: [ComicRow] = []
    @State private var showingXLSXImportPreview = false
    @State private var xlsxDocument: XLSXDocument?
    @State private var showingXLSXExporter = false
    @State private var showingXLSXImporter = false
    @State private var xlsxErrorMessage: String?
    @State private var showingXLSXError = false

    enum SortOrder: String, CaseIterable {
        case title     = "Title"
        case author    = "Author"
        case publisher = "Publisher"
        case date      = "Date"

        var icon: String {
            switch self {
            case .title:     return "textformat"
            case .author:    return "person"
            case .publisher: return "building.2"
            case .date:      return "calendar"
            }
        }
    }

    enum ReadFilter: String, CaseIterable, Identifiable {
        case all       = "All"
        case unread    = "Unread"
        case reading   = "Reading"
        case paused    = "Paused"
        case finished  = "Finished"
        case abandoned = "Abandoned"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                lists: lists,
                comics: comics,
                selectedList: $selectedList,
                viewModel: viewModel
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            if let list = selectedList {
                if list.isReadingOrder {
                    ReadingOrderContentView(list: list, viewModel: viewModel)
                } else if list.isWishlist {
                    WishlistContentView(list: list, viewModel: viewModel)
                } else {
                    VStack(spacing: 0) {
                        // Suggestions panel — shown only in My Collection
                        if list.isMainCollection {
                            let suggestions = viewModel?.suggestedComics(
                                allComics: comics, allLists: lists
                            ) ?? []
                            if !suggestions.isEmpty {
                                WhatToReadNextView(comics: suggestions) { comic in
                                    selectedComicFromSuggestion = comic
                                }
                                Divider()
                            }
                        }

                        if let series = selectedSeries {
                            // Back bar
                            HStack(spacing: 8) {
                                Button { selectedSeries = nil } label: {
                                    Label("All Series", systemImage: "chevron.left")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(Color.accentColor)

                                Text(series)
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            Divider()

                            ComicGridView(
                                comics: sortedComics.filter { $0.series == series },
                                onAddComic: { showingAddComic = true },
                                viewModel: viewModel
                            )
                        } else {
                            SeriesGridView(
                                comics: sortedComics,
                                viewModel: viewModel,
                                onSelectSeries: { selectedSeries = $0 },
                                onAddComic: { showingAddComic = true }
                            )
                        }
                    }
                    .searchable(text: $searchText, placement: .toolbar, prompt: "Search comics...")
                    .onChange(of: selectedList) { _, _ in selectedSeries = nil }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Menu {
                    Picker("Sort", selection: $sortOrder) {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Label(order.rawValue, systemImage: order.icon).tag(order)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
                .help("Change sort order")

                Menu {
                    Picker("Filter", selection: $readFilter) {
                        ForEach(ReadFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
                .help("Filter by read status")

                Button {
                    showingMALImport = true
                } label: {
                    Label("Import from MAL", systemImage: "arrow.down.circle")
                }
                .help("Import manga from MyAnimeList")

                Menu {
                    Button {
                        do {
                            let data = try XLSXService.shared.exportData(comics: comics)
                            xlsxDocument = XLSXDocument(data: data)
                            showingXLSXExporter = true
                        } catch {
                            xlsxErrorMessage = error.localizedDescription
                            showingXLSXError = true
                        }
                    } label: {
                        Label("Export as XLSX...", systemImage: "arrow.up.doc")
                    }

                    Button {
                        showingXLSXImporter = true
                    } label: {
                        Label("Import from XLSX...", systemImage: "arrow.down.doc")
                    }
                } label: {
                    Label("XLSX", systemImage: "tablecells")
                }
                .help("Import or export comics as spreadsheet")
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ComicViewModel(modelContext: modelContext)
            }
            ensureSystemListsExist()
            if selectedList == nil, let first = lists.first {
                selectedList = first
            }
        }
        .sheet(isPresented: $showingAddComic) {
            if let viewModel = viewModel {
                AddComicSheet(viewModel: viewModel, targetList: selectedList)
            }
        }
        .sheet(isPresented: $showingMALImport) {
            if let viewModel = viewModel {
                MALImportView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingXLSXImportPreview) {
            if let viewModel = viewModel {
                XLSXImportPreviewView(
                    rows: xlsxImportRows,
                    existingTitles: Set(comics.map { $0.title.lowercased() })
                ) { skipDuplicates in
                    viewModel.importComics(rows: xlsxImportRows, skipDuplicates: skipDuplicates)
                }
            }
        }
        .fileExporter(
            isPresented: $showingXLSXExporter,
            document: xlsxDocument,
            contentType: UTType(filenameExtension: "xlsx") ?? .data,
            defaultFilename: "ComicArchiv_Export"
        ) { result in
            xlsxDocument = nil
            if case .failure(let error) = result {
                xlsxErrorMessage = error.localizedDescription
                showingXLSXError = true
            }
        }
        .fileImporter(
            isPresented: $showingXLSXImporter,
            allowedContentTypes: [UTType(filenameExtension: "xlsx") ?? .data]
        ) { result in
            switch result {
            case .success(let url):
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                do {
                    xlsxImportRows = try XLSXService.shared.importComics(from: url)
                    showingXLSXImportPreview = true
                } catch {
                    xlsxErrorMessage = error.localizedDescription
                    showingXLSXError = true
                }
            case .failure(let error):
                xlsxErrorMessage = error.localizedDescription
                showingXLSXError = true
            }
        }
        .alert("XLSX Error", isPresented: $showingXLSXError) {
            Button("OK") {}
        } message: {
            Text(xlsxErrorMessage ?? "An unknown error occurred.")
        }
        .sheet(item: $selectedComicFromSuggestion) { comic in
            if let viewModel = viewModel {
                ComicDetailView(comic: comic, viewModel: viewModel) {
                    selectedComicFromSuggestion = nil
                }
            }
        }
        .navigationTitle(selectedList?.name ?? "Comic Archiv")
    }

    private var filteredComics: [Comic] {
        guard let selectedList else { return comics }
        return selectedList.comics
    }

    private var searchFilteredComics: [Comic] {
        var result = filteredComics

        if !searchText.isEmpty {
            result = result.filter { comic in
                comic.title.localizedCaseInsensitiveContains(searchText) ||
                comic.author.localizedCaseInsensitiveContains(searchText) ||
                comic.publisher.localizedCaseInsensitiveContains(searchText) ||
                comic.issueNumber.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch readFilter {
        case .all:       break
        case .unread:    result = result.filter { $0.readStatus == .unread }
        case .reading:   result = result.filter { $0.readStatus == .reading }
        case .paused:    result = result.filter { $0.readStatus == .paused }
        case .finished:  result = result.filter { $0.readStatus == .finished }
        case .abandoned: result = result.filter { $0.readStatus == .abandoned }
        }

        return result
    }

    private var sortedComics: [Comic] {
        switch sortOrder {
        case .title:     return searchFilteredComics.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .author:    return searchFilteredComics.sorted { $0.author.localizedCompare($1.author) == .orderedAscending }
        case .publisher: return searchFilteredComics.sorted { $0.publisher.localizedCompare($1.publisher) == .orderedAscending }
        case .date:      return searchFilteredComics.sorted { $0.releaseDate > $1.releaseDate }
        }
    }

    private func ensureSystemListsExist() {
        let descriptor = FetchDescriptor<ComicList>(predicate: #Predicate { $0.isMainCollection })
        if (try? modelContext.fetch(descriptor).first) == nil {
            let mainCollection = ComicList(
                name: "My Collection",
                icon: "books.vertical.fill",
                isMainCollection: true
            )
            modelContext.insert(mainCollection)
        }
        viewModel?.ensureWishlistExists()
        try? modelContext.save()
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Comic.self, ComicList.self], inMemory: true)
}
