//
//  EditListSheet.swift
//  Comic Archiv
//

import SwiftUI

struct EditListSheet: View {
    @Environment(\.dismiss) private var dismiss

    let list: ComicList
    let viewModel: ComicViewModel

    @State private var name: String
    @State private var selectedIcon: String

    private var availableIcons: [String] {
        list.isReadingOrder
        ? ["list.number", "list.bullet.rectangle", "books.vertical", "book.pages", "text.book.closed"]
        : ["star.fill", "heart.fill", "bookmark.fill", "folder.fill", "tray.fill",
           "flag.fill", "tag.fill", "books.vertical.fill", "book.closed.fill", "checkmark.circle.fill"]
    }

    init(list: ComicList, viewModel: ComicViewModel) {
        self.list = list
        self.viewModel = viewModel
        _name = State(initialValue: list.name)
        _selectedIcon = State(initialValue: list.icon ?? (list.isReadingOrder ? "list.number" : "star.fill"))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("List Details") {
                    TextField("Name", text: $name)
                    Picker("Icon", selection: $selectedIcon) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Image(systemName: icon).tag(icon)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Preview") {
                    Label { Text(name) } icon: { Image(systemName: selectedIcon) }
                        .font(.headline)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit List")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }.disabled(name.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }

    private func saveChanges() {
        list.name = name
        list.icon = selectedIcon
        viewModel.updateList(list)
        dismiss()
    }
}
