//
//  TestReadingOrder.swift
//  Comic Archiv
//
//  Temporäre Test-Datei für Phase 1
//

import Foundation
import SwiftData

class ReadingOrderTester {
    
    static func runTests(modelContext: ModelContext, comics: [Comic]) {
        print("\n========================================")
        print("🧪 READING ORDER TESTS START")
        print("========================================\n")
        
        // Test 1: Reading Order erstellen
        test1_CreateReadingOrder(modelContext: modelContext)
        
        // Test 2: Platzhalter hinzufügen
        test2_AddPlaceholders(modelContext: modelContext)
        
        // Test 3: Comic aus Sammlung hinzufügen
        if !comics.isEmpty {
            test3_AddComicFromCollection(modelContext: modelContext, comic: comics.first!)
        }
        
        // Test 4: Status prüfen
        test4_CheckStatus(modelContext: modelContext)
        
        // Test 5: Position ändern
        test5_ChangePosition(modelContext: modelContext)
        
        print("\n========================================")
        print("✅ ALLE TESTS ABGESCHLOSSEN")
        print("========================================\n")
    }
    
    // MARK: - Test 1: Reading Order erstellen
    static func test1_CreateReadingOrder(modelContext: ModelContext) {
        print("📝 Test 1: Reading Order erstellen")
        
        let dcOrder = ComicListe(
            name: "DC Rebirth Reading Order",
            icon: "list.number",
            istReadingOrder: true
        )
        
        modelContext.insert(dcOrder)
        try? modelContext.save()
        
        print("   ✓ Liste erstellt: \(dcOrder.name)")
        print("   ✓ istReadingOrder: \(dcOrder.istReadingOrder)")
        print()
    }
    
    // MARK: - Test 2: Platzhalter hinzufügen
    static func test2_AddPlaceholders(modelContext: ModelContext) {
        print("📝 Test 2: Platzhalter hinzufügen")
        
        // Liste finden
        let descriptor = FetchDescriptor<ComicListe>(
            predicate: #Predicate { $0.istReadingOrder }
        )
        guard let liste = try? modelContext.fetch(descriptor).first else {
            print("   ❌ Keine Reading Order gefunden")
            return
        }
        
        // Platzhalter erstellen
        let entry1 = ReadingOrderEntry(position: 1, placeholderName: "DC Universe Rebirth #1")
        entry1.liste = liste
        modelContext.insert(entry1)
        
        let entry2 = ReadingOrderEntry(position: 2, placeholderName: "Batman: Rebirth #1")
        entry2.liste = liste
        modelContext.insert(entry2)
        
        let entry3 = ReadingOrderEntry(position: 3, placeholderName: "Superman: Rebirth #1")
        entry3.liste = liste
        modelContext.insert(entry3)
        
        try? modelContext.save()
        
        print("   ✓ 3 Platzhalter erstellt")
        print("   ✓ Entry 1: \(entry1.displayName) - Status: \(entry1.isPlaceholder ? "🛒 Zu kaufen" : "📖")")
        print("   ✓ Entry 2: \(entry2.displayName) - Status: \(entry2.isPlaceholder ? "🛒 Zu kaufen" : "📖")")
        print("   ✓ Entry 3: \(entry3.displayName) - Status: \(entry3.isPlaceholder ? "🛒 Zu kaufen" : "📖")")
        print()
    }
    
    // MARK: - Test 3: Comic aus Sammlung hinzufügen
    static func test3_AddComicFromCollection(modelContext: ModelContext, comic: Comic) {
        print("📝 Test 3: Comic aus Sammlung hinzufügen")
        
        let descriptor = FetchDescriptor<ComicListe>(
            predicate: #Predicate { $0.istReadingOrder }
        )
        guard let liste = try? modelContext.fetch(descriptor).first else {
            print("   ❌ Keine Reading Order gefunden")
            return
        }
        
        let entry4 = ReadingOrderEntry(position: 4, comic: comic)
        entry4.liste = liste
        modelContext.insert(entry4)
        
        try? modelContext.save()
        
        print("   ✓ Comic hinzugefügt: \(entry4.displayName)")
        print("   ✓ Position: \(entry4.position)")
        print("   ✓ Status: \(comic.gelesen ? "✅ Gelesen" : "📖 Ungelesen")")
        print()
    }
    
    // MARK: - Test 4: Status & Fortschritt prüfen
    static func test4_CheckStatus(modelContext: ModelContext) {
        print("📝 Test 4: Status & Fortschritt prüfen")
        
        let descriptor = FetchDescriptor<ComicListe>(
            predicate: #Predicate { $0.istReadingOrder }
        )
        guard let liste = try? modelContext.fetch(descriptor).first else {
            print("   ❌ Keine Reading Order gefunden")
            return
        }
        
        print("   Liste: \(liste.name)")
        print("   Entries: \(liste.readingOrderEntries.count)")
        
        if let progress = liste.readingProgress {
            print("   📊 Fortschritt:")
            print("      - Gelesen: \(progress.gelesen)")
            print("      - Gesamt: \(progress.gesamt)")
            print("      - Zu kaufen: \(progress.zuKaufen)")
        }
        
        print("\n   📋 Alle Entries:")
        for entry in liste.sortedReadingOrderEntries {
            let statusIcon = entry.isPlaceholder ? "🛒" : (entry.comic?.gelesen == true ? "✅" : "📖")
            print("      \(entry.position). \(statusIcon) \(entry.displayName)")
        }
        print()
    }
    
    // MARK: - Test 5: Position ändern
    static func test5_ChangePosition(modelContext: ModelContext) {
        print("📝 Test 5: Position ändern (Entry 4 → Position 2)")
        
        let descriptor = FetchDescriptor<ComicListe>(
            predicate: #Predicate { $0.istReadingOrder }
        )
        guard let liste = try? modelContext.fetch(descriptor).first else {
            print("   ❌ Keine Reading Order gefunden")
            return
        }
        
        // Entry an Position 4 finden
        guard let entry = liste.readingOrderEntries.first(where: { $0.position == 4 }) else {
            print("   ⚠️ Kein Entry an Position 4")
            return
        }
        
        let oldPosition = entry.position
        let newPosition = 2
        
        // Entries zwischen den Positionen verschieben
        let affectedEntries = liste.readingOrderEntries.filter {
            $0.position >= newPosition && $0.position < oldPosition
        }
        for affectedEntry in affectedEntries {
            affectedEntry.position += 1
        }
        
        entry.position = newPosition
        try? modelContext.save()
        
        print("   ✓ Entry verschoben: Position \(oldPosition) → \(newPosition)")
        print("\n   📋 Neue Reihenfolge:")
        for entry in liste.sortedReadingOrderEntries {
            let statusIcon = entry.isPlaceholder ? "🛒" : (entry.comic?.gelesen == true ? "✅" : "📖")
            print("      \(entry.position). \(statusIcon) \(entry.displayName)")
        }
        print()
    }
}
