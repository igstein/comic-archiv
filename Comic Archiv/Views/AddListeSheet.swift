//
//  AddListSheet.swift
//  Comic Archiv
//

import SwiftUI

struct AddListSheet: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: ComicViewModel

    @State private var name = ""
    @State private var selectedIcon = "star.fill"

    private let availableIcons = [
        "star.fill", "heart.fill", "bookmark.fill", "folder.fill",
        "tray.fill", "flag.fill", "tag.fill", "books.vertical.fill",
        "book.closed.fill", "checkmark.circle.fill"
    ]

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
                    Label {
                        Text(name.isEmpty ? "My List" : name)
                    } icon: {
                        Image(systemName: selectedIcon)
                    }
                    .font(.headline)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New List")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createList() }.disabled(name.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }

    private func createList() {
        let newList = ComicList(name: name, icon: selectedIcon)
        viewModel.addList(newList)
        dismiss()
    }
}
