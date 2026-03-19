//
//  XLSXImportPreviewView.swift
//  Comic Archiv
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - FileDocument wrapper used by SwiftUI's fileExporter

struct XLSXDocument: FileDocument, @unchecked Sendable {
    static var readableContentTypes: [UTType] { [UTType(filenameExtension: "xlsx") ?? .data] }

    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct XLSXImportPreviewView: View {
    let rows: [ComicRow]
    let existingTitles: Set<String>
    let onImport: (_ skipDuplicates: Bool) -> Void

    @Environment(\.dismiss) private var dismiss

    private var newRows: [ComicRow] {
        rows.filter { !existingTitles.contains($0.title.lowercased()) }
    }

    private var duplicateRows: [ComicRow] {
        rows.filter { existingTitles.contains($0.title.lowercased()) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Import from XLSX")
                        .font(.headline)
                    Text("\(rows.count) comics found · \(newRows.count) new · \(duplicateRows.count) duplicates")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Cancel") { dismiss() }
            }
            .padding()

            Divider()

            // Comic list
            List {
                if !newRows.isEmpty {
                    Section("New (\(newRows.count))") {
                        ForEach(newRows, id: \.title) { row in
                            ComicImportRow(row: row, isDuplicate: false)
                        }
                    }
                }

                if !duplicateRows.isEmpty {
                    Section("Already in Collection (\(duplicateRows.count))") {
                        ForEach(duplicateRows, id: \.title) { row in
                            ComicImportRow(row: row, isDuplicate: true)
                        }
                    }
                }
            }
            .listStyle(.inset)

            Divider()

            // Action buttons
            HStack(spacing: 12) {
                Spacer()

                if !duplicateRows.isEmpty {
                    Button("Import New Only (\(newRows.count))") {
                        onImport(true)
                        dismiss()
                    }
                    .disabled(newRows.isEmpty)
                }

                Button("Import All (\(rows.count))") {
                    onImport(false)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(rows.isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

private struct ComicImportRow: View {
    let row: ComicRow
    let isDuplicate: Bool

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .fontWeight(.medium)
                    .foregroundStyle(isDuplicate ? .secondary : .primary)

                HStack(spacing: 8) {
                    if !row.series.isEmpty && row.series != row.title {
                        Text(row.series)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !row.author.isEmpty {
                        Text(row.author)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if isDuplicate {
                Text("Duplicate")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            }

            if !row.readStatus.isEmpty {
                Text(row.readStatus.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
