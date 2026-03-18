//
//  TestReadingOrder.swift
//  Comic Archiv
//

import Foundation
import SwiftData

class ReadingOrderTester {

    static func runTests(modelContext: ModelContext, comics: [Comic]) {
        print("\n========================================")
        print("READING ORDER TESTS START")
        print("========================================\n")

        test1_createReadingOrder(modelContext: modelContext)
        test2_addPlaceholders(modelContext: modelContext)
        if !comics.isEmpty {
            test3_addComicFromCollection(modelContext: modelContext, comic: comics.first!)
        }
        test4_checkStatus(modelContext: modelContext)
        test5_changePosition(modelContext: modelContext)

        print("\n========================================")
        print("ALL TESTS COMPLETE")
        print("========================================\n")
    }

    static func test1_createReadingOrder(modelContext: ModelContext) {
        print("Test 1: Create reading order")
        let order = ComicList(name: "DC Rebirth Reading Order", icon: "list.number", isReadingOrder: true)
        modelContext.insert(order)
        try? modelContext.save()
        print("   Created: \(order.name)\n")
    }

    static func test2_addPlaceholders(modelContext: ModelContext) {
        print("Test 2: Add placeholders")
        let descriptor = FetchDescriptor<ComicList>(predicate: #Predicate { $0.isReadingOrder })
        guard let list = try? modelContext.fetch(descriptor).first else {
            print("   No reading order found\n"); return
        }
        let e1 = ReadingOrderEntry(position: 1, placeholderName: "DC Universe Rebirth #1")
        e1.list = list; modelContext.insert(e1)
        let e2 = ReadingOrderEntry(position: 2, placeholderName: "Batman: Rebirth #1")
        e2.list = list; modelContext.insert(e2)
        try? modelContext.save()
        print("   Added 2 placeholders\n")
    }

    static func test3_addComicFromCollection(modelContext: ModelContext, comic: Comic) {
        print("Test 3: Add comic from collection")
        let descriptor = FetchDescriptor<ComicList>(predicate: #Predicate { $0.isReadingOrder })
        guard let list = try? modelContext.fetch(descriptor).first else {
            print("   No reading order found\n"); return
        }
        let entry = ReadingOrderEntry(position: 3, comic: comic)
        entry.list = list; modelContext.insert(entry)
        try? modelContext.save()
        print("   Added: \(entry.displayName) at position \(entry.position)\n")
    }

    static func test4_checkStatus(modelContext: ModelContext) {
        print("Test 4: Check progress")
        let descriptor = FetchDescriptor<ComicList>(predicate: #Predicate { $0.isReadingOrder })
        guard let list = try? modelContext.fetch(descriptor).first else {
            print("   No reading order found\n"); return
        }
        if let p = list.readingProgress {
            print("   Progress: \(p.read)/\(p.total) read, \(p.toBuy) to buy")
        }
        for entry in list.sortedReadingOrderEntries {
            let icon = entry.isPlaceholder ? "[to buy]" : (entry.comic?.readStatus == .finished ? "[read]" : "[unread]")
            print("   \(entry.position). \(icon) \(entry.displayName)")
        }
        print()
    }

    static func test5_changePosition(modelContext: ModelContext) {
        print("Test 5: Change position")
        let descriptor = FetchDescriptor<ComicList>(predicate: #Predicate { $0.isReadingOrder })
        guard let list = try? modelContext.fetch(descriptor).first,
              let entry = list.readingOrderEntries.first(where: { $0.position == 3 }) else {
            print("   No entry at position 3\n"); return
        }
        let old = entry.position
        let new = 1
        for e in list.readingOrderEntries where e.position >= new && e.position < old { e.position += 1 }
        entry.position = new
        try? modelContext.save()
        print("   Moved \(old) -> \(new)\n")
    }
}
