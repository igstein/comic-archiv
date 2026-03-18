//
//  Comic_ArchivApp.swift
//  Comic Archiv
//

import SwiftUI
import SwiftData

@main
struct Comic_ArchivApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Comic.self,
            ComicListe.self,
            ReadingOrderEntry.self,
            PlaceholderComic.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Comic hinzufügen") {
                    // Wird über Keyboard Shortcut in der View behandelt
                }
                .keyboardShortcut("n", modifiers: .command)
                .disabled(true)  // Wird nur für Menü-Anzeige verwendet
                
                Divider()
                
                Button("Neue Liste") {
                    // Wird über Keyboard Shortcut in der View behandelt
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
                .disabled(true)  // Wird nur für Menü-Anzeige verwendet
            }
        }
    }
}
