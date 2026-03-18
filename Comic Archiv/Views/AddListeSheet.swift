//
//  AddListeSheet.swift
//  Comic Archiv
//

import SwiftUI

struct AddListeSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let viewModel: ComicViewModel
    
    @State private var name = ""
    @State private var selectedIcon = "star.fill"
    
    // Auswahl an Icons (ohne list.bullet - nur für Reading Orders)
    private let availableIcons = [
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
                        Text(name.isEmpty ? "Meine Liste" : name)
                    } icon: {
                        Image(systemName: selectedIcon)
                    }
                    .font(.headline)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Neue Liste")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Erstellen") {
                        createListe()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private func createListe() {
        let newListe = ComicListe(
            name: name,
            icon: selectedIcon
        )
        
        viewModel.addListe(newListe)
        dismiss()
    }
}
