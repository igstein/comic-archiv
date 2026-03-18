//
//  ComicSearchSection.swift
//  Comic Archiv
//

import SwiftUI

// MARK: - Reusable search section for add-comic sheets

struct ComicSearchSection: View {
    let onSelect: (ComicSearchResult) -> Void

    @State private var query            = ""
    @State private var results:         [ComicSearchResult] = []
    @State private var isSearching      = false
    @State private var searchTask:      Task<Void, Never>?
    @State private var showingMetronSetup = false
    @State private var metronConfigured = KeychainHelper.metronUsername != nil

    var body: some View {
        Section {
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

            // Metron setup prompt
            if !metronConfigured {
                HStack {
                    Image(systemName: "info.circle").foregroundStyle(.secondary)
                    Text("Add Metron credentials for Western comics")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("Configure") { showingMetronSetup = true }
                        .font(.caption)
                }
            }
        } header: {
            Text("Auto-fill from Search")
        }
        .sheet(isPresented: $showingMetronSetup, onDismiss: {
            metronConfigured = KeychainHelper.metronUsername != nil
        }) {
            MetronSetupSheet()
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
            let found = await ComicSearchService.shared.search(query: trimmed)
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
            // Source badge
            Text(result.source.label)
                .font(.caption2).fontWeight(.semibold)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Capsule().fill(result.source.color.opacity(0.15)))
                .foregroundStyle(result.source.color)

            // Cover thumbnail
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

            // Info
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

// MARK: - Metron Credentials Setup

struct MetronSetupSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var username = KeychainHelper.metronUsername ?? ""
    @State private var password = KeychainHelper.metronPassword ?? ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Username", text: $username)
                    SecureField("Password", text: $password)
                } header: {
                    Text("Metron Account")
                } footer: {
                    Text("Register for free at metron.cloud. Credentials are stored in the macOS Keychain.")
                        .font(.caption)
                }

                if KeychainHelper.metronUsername != nil {
                    Section {
                        Button(role: .destructive) {
                            KeychainHelper.metronUsername = nil
                            KeychainHelper.metronPassword = nil
                            username = ""
                            password = ""
                        } label: {
                            Label("Remove Credentials", systemImage: "trash")
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Metron Credentials")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        KeychainHelper.metronUsername = username
                        KeychainHelper.metronPassword = password
                        dismiss()
                    }
                    .disabled(username.isEmpty || password.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 240)
    }
}
