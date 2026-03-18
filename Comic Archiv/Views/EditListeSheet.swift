//
//  EditListeSheet.swift
//  Comic Archiv
//

import SwiftUI

struct EditListeSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let liste: ComicListe
    let viewModel: ComicViewModel
    
    @State private var name: String
    @State private var selectedIcon: String
    
    // Icons je nach Listen-Typ
    private var availableIcons: [String] {
        if liste.istReadingOrder {
            return [
                "list.number",
                "list.bullet.rectangle",
                "books.vertical",
                "book.pages",
                "text.book.closed"
            ]
        } else {
            return [
                "star.fill",
                "heart.fill",
                "bookmark.fill",
                "folder.fill",
                "tray.fill",
                "flag.fill",
                "tag.fill",
                "books.vertical.fill",
                "book.closed.fill",
                "checkmark.circle.fill"
            ]
        }
    }
    
    init(liste: ComicListe, viewModel: ComicViewModel) {
        self.liste = liste
        self.viewModel = viewModel
        
        _name = State(initialValue: liste.name)
        _selectedIcon = State(initialValue: liste.icon ?? (liste.istReadingOrder ? "list.number" : "star.fill"))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Listen-Details") {
                    TextField("Name", text: $name)
                    
                    Picker("Icon", selection: $selectedIcon) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .tag(icon)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Vorschau") {
                    Label {
                        Text(name)
                    } icon: {
                        Image(systemName: selectedIcon)
                    }
                    .font(.headline)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Liste bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private func saveChanges() {
        liste.name = name
        liste.icon = selectedIcon
        viewModel.updateListe(liste)
        dismiss()
    }
}
