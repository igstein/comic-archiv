//
//  ComicSearchSection.swift
//  Comic Archiv
//

import SwiftUI

// MARK: - Reusable search section for add-comic sheets

struct ComicSearchSection: View {
    let onSelect: (ComicSearchResult) -> Void

    @AppStorage("comicvine_api_key") private var comicVineApiKey = ""

    @State private var query          = ""
    @State private var results:       [ComicSearchResult] = []
    @State private var isSearching    = false
    @State private var searchTask:    Task<Void, Never>?
    @State private var showingCVSetup = false
    @State private var cvMode:        CVSearchMode = .issues

    private var cvConfigured: Bool { !comicVineApiKey.isEmpty }

    var body: some View {
        Section {
            // Issues / Trades toggle (only shown when CV is configured)
            if cvConfigured {
                Picker("Search Mode", selection: $cvMode) {
                    Text("Issues").tag(CVSearchMode.issues)
                    Text("Trades").tag(CVSearchMode.trades)
                }
                .pickerStyle(.segmented)
                .onChange(of: cvMode) { _, _ in
                    results = []
                    scheduleSearch(query)
                }
            }

            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search comics & manga…", text: $query)
                    .textFieldStyle(.plain)
                if isSearching {
                    ProgressView().scaleEffect(0.7)
                } else if !query.isEmpty {
                    Button {
                        query   = ""
                        results = []
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .onChange(of: query) { _, newValue in scheduleSearch(newValue) }

            // Results
            ForEach(results) { result in
                Button {
                    onSelect(result)
                    query   = ""
                    results = []
                } label: {
                    SearchResultRow(result: result)
                }
                .buttonStyle(.plain)
            }

            // Comic Vine credential row — always visible
            HStack {
                Image(systemName: cvConfigured ? "checkmark.circle.fill" : "info.circle")
                    .foregroundStyle(cvConfigured ? .green : .secondary)
                Text(cvConfigured ? "Comic Vine: configured" : "Add Comic Vine API key for Western comics")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(cvConfigured ? "Change" : "Configure") { showingCVSetup = true }
                    .font(.caption)
            }
        } header: {
            Text("Auto-fill from Search")
        }
        .sheet(isPresented: $showingCVSetup) {
            ComicVineSetupSheet()
        }
    }

    private func scheduleSearch(_ newQuery: String) {
        searchTask?.cancel()
        let trimmed = newQuery.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { results = []; return }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await MainActor.run { isSearching = true }
            let found = await ComicSearchService.shared.search(query: trimmed, cvMode: cvMode)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                results     = found
                isSearching = false
            }
        }
    }
}

// MARK: - Result Row

struct SearchResultRow: View {
    let result: ComicSearchResult

    var body: some View {
        HStack(spacing: 10) {
            Text(result.source.label)
                .font(.caption2).fontWeight(.semibold)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Capsule().fill(result.source.color.opacity(0.15)))
                .foregroundStyle(result.source.color)

            AsyncImage(url: result.coverURL) { phase in
                if case .success(let image) = phase {
                    image.resizable().aspectRatio(contentMode: .fill)
                        .frame(width: 28, height: 42)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                } else {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 28, height: 42)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(result.title).font(.headline).lineLimit(1)
                    if !result.issueNumber.isEmpty {
                        Text(result.issueNumber)
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                if !result.publisher.isEmpty {
                    Text(result.publisher).font(.caption).foregroundStyle(.tertiary)
                }
            }

            Spacer()
            Image(systemName: "arrow.right.circle").foregroundStyle(.tertiary).font(.caption)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }
}

// MARK: - Comic Vine API Key Setup

struct ComicVineSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("comicvine_api_key") private var savedKey = ""
    @State private var apiKey = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("API Key", text: $apiKey)
                } header: {
                    Text("Comic Vine API Key")
                } footer: {
                    Text("Get a free API key at comicvine.gamespot.com/api/")
                        .font(.caption)
                }

                if !savedKey.isEmpty {
                    Section {
                        Button(role: .destructive) {
                            savedKey = ""
                            apiKey   = ""
                        } label: {
                            Label("Remove API Key", systemImage: "trash")
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Comic Vine")
            .onAppear { apiKey = savedKey }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 220)
    }
}
