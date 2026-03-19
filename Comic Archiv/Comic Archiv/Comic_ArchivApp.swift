//
//  Comic_ArchivApp.swift
//  Comic Archiv
//

import SwiftUI
import SwiftData

@main
struct Comic_ArchivApp: App {
var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(
                for: Schema(versionedSchema: SchemaV1.self),
                migrationPlan: AppMigrationPlan.self
            )
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
