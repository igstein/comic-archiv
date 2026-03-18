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
                    TextField("", text: $name, prompt: Text("e.g. DC Rebirth Timeline"))
                }
            }
            .navigationTitle("New Reading Order")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createReadingOrder() }.disabled(name.isEmpty)
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
