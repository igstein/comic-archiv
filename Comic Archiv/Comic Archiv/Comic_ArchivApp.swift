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
            ComicList.self,
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
                Button("Add Comic") { }
                    .keyboardShortcut("n", modifiers: .command)
                    .disabled(true)

                Divider()

                Button("New List") { }
                    .keyboardShortcut("l", modifiers: [.command, .shift])
                    .disabled(true)
            }
        }
    }
}
