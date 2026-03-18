//
//  AddReadingOrderSheet.swift
//  Comic Archiv
//

import SwiftUI

struct AddReadingOrderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: ComicViewModel
    
    @State private var name: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("", text: $name, prompt: Text("z.B. DC Rebirth Timeline"))
                }
            }
            .navigationTitle("Neue Reading Order")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Erstellen") {
                        createReadingOrder()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(width: 400, height: 200)
    }
    
    private func createReadingOrder() {
        viewModel.createReadingOrder(name: name, icon: "list.number")
        dismiss()
    }
}
