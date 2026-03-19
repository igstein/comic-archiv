//
//  ComicViewModel.swift
//  Comic Archiv
//

import Foundation
import SwiftData
import AppKit

@Observable
class ComicViewModel {
    var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Comic Operations

    func addComic(_ comic: Comic, toList list: ComicList? = nil) {
        modelContext.insert(comic)
        if let list = list {
            list.comics.append(comic)
        }
        save()
    }

    func updateComic(_ comic: Comic) {
        save()
    }

    func deleteComic(_ comic: Comic) {
        if let fileName = comic.coverImageName {
            ImageManager.shared.deleteImage(named: fileName)
        }
        modelContext.delete(comic)
        save()
    }

    func addComicToList(_ comic: Comic, list: ComicList) {
        if !list.comics.contains(where: { $0.id == comic.id }) {
            list.comics.append(comic)
            save()
        }
    }

    func removeComicFromList(_ comic: Comic, list: ComicList) {
        list.comics.removeAll(where: { $0.id == comic.id })
        save()
    }

    // MARK: - List Operations

    func addList(_ list: ComicList) {
        modelContext.insert(list)
        save()
    }

    func updateList(_ list: ComicList) {
        save()
    }

    func deleteList(_ list: ComicList) {
        guard !list.isMainCollection else { return }
        modelContext.delete(list)
        save()
    }

    // MARK: - Cover Image Operations

    func setCoverImage(_ image: NSImage, for comic: Comic) {
        if let oldFileName = comic.coverImageName {
            ImageManager.shared.deleteImage(named: oldFileName)
        }
        if let fileName = ImageManager.shared.saveImage(image) {
            comic.coverImageName = fileName
            save()
        }
    }

    func removeCoverImage(from comic: Comic) {
        if let fileName = comic.coverImageName {
            ImageManager.shared.deleteImage(named: fileName)
            comic.coverImageName = nil
            save()
        }
    }

    // MARK: - Reading Order Operations

    func createReadingOrder(name: String, icon: String) {
        let readingOrder = ComicList(name: name, icon: icon, isReadingOrder: true)
        modelContext.insert(readingOrder)
        try? modelContext.save()
    }

    /// Returns true on success, false if the comic is already in this reading order.
    func addComicToReadingOrder(_ comic: Comic, readingOrder: ComicList) -> Bool {
        guard readingOrder.isReadingOrder else { return false }

        let existingIDs = readingOrder.readingOrderEntries.compactMap { $0.comic?.id }
        if existingIDs.contains(comic.id) { return false }

        let newPosition = (readingOrder.readingOrderEntries.map { $0.position }.max() ?? 0) + 1
        let entry = ReadingOrderEntry(position: newPosition, comic: comic)
        entry.list = readingOrder
        modelContext.insert(entry)
        save()
        return true
    }

    // MARK: - System List Setup

    func ensureWishlistExists() {
        let descriptor = FetchDescriptor<ComicList>(predicate: #Predicate { $0.isWishlist })
        if (try? modelContext.fetch(descriptor).first) == nil {
            let wishlist = ComicList(name: "Wishlist", icon: "cart", isWishlist: true)
            modelContext.insert(wishlist)
            save()
        }
    }

    func getWishlist() -> ComicList? {
        ensureWishlistExists()
        let descriptor = FetchDescriptor<ComicList>(predicate: #Predicate { $0.isWishlist })
        return try? modelContext.fetch(descriptor).first
    }

    // MARK: - Placeholder & Wishlist

    func createPlaceholder(name: String) -> PlaceholderComic {
        let descriptor = FetchDescriptor<PlaceholderComic>(
            predicate: #Predicate { $0.name == name }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let placeholder = PlaceholderComic(name: name)
        modelContext.insert(placeholder)
        save()
        return placeholder
    }

    func convertPlaceholdersToComic(_ comic: Comic) {
        let comicTitle = comic.title
        let descriptor = FetchDescriptor<PlaceholderComic>(
            predicate: #Predicate { $0.name == comicTitle }
        )
        guard let placeholders = try? modelContext.fetch(descriptor) else { return }
        for placeholder in placeholders {
            for entry in placeholder.readingOrderEntries {
                entry.comic = comic
                entry.placeholder = nil
            }
            modelContext.delete(placeholder)
        }
        save()
    }

    func cleanupPlaceholderIfUnused(_ placeholder: PlaceholderComic) {
        if placeholder.readingOrderEntries.isEmpty {
            modelContext.delete(placeholder)
            save()
        }
    }

    func getWishlistPlaceholders() -> [PlaceholderComic] {
        let descriptor = FetchDescriptor<PlaceholderComic>(
            predicate: #Predicate { $0.inWishlist == true },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Suggestions ("What to Read Next")

    func suggestedComics(allComics: [Comic], allLists: [ComicList]) -> [Comic] {
        let candidates = allComics.filter { $0.readStatus != .finished }

        // IDs of the first unread comic in each reading order
        let nextInOrderIDs: Set<UUID> = Set(
            allLists
                .filter { $0.isReadingOrder }
                .compactMap { list in
                    list.sortedReadingOrderEntries
                        .first { $0.comic != nil && $0.comic?.readStatus != .finished }?
                        .comic?.id
                }
        )

        let scored: [(Comic, Double)] = candidates.map { comic in
            var score = 0.0

            switch comic.priority {
            case .mustRead: score += 40
            case .high:     score += 30
            case .medium:   score += 20
            case .low:      score += 10
            }

            if comic.readStatus == .reading { score += 25 }
            if nextInOrderIDs.contains(comic.id) { score += 20 }

            let days = Calendar.current.dateComponents([.day], from: comic.createdAt, to: Date()).day ?? 365
            if days < 30 { score += 5 }

            return (comic, score)
        }

        return scored
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { $0.0 }
    }

    // MARK: - XLSX Import

    func importComics(rows: [ComicRow], skipDuplicates: Bool) {
        let allComics = (try? modelContext.fetch(FetchDescriptor<Comic>())) ?? []
        let existingTitles = Set(allComics.map { $0.title.lowercased() })

        let descriptor = FetchDescriptor<ComicList>(predicate: #Predicate { $0.isMainCollection })
        guard let mainCollection = try? modelContext.fetch(descriptor).first else { return }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")

        let fallbackDate: Date = {
            var c = DateComponents(); c.year = 1900; c.month = 1; c.day = 1
            return Calendar.current.date(from: c) ?? Date()
        }()

        for row in rows {
            if skipDuplicates && existingTitles.contains(row.title.lowercased()) { continue }

            let comic = Comic(
                title: row.title,
                author: row.author,
                artist: row.artist,
                publisher: row.publisher,
                releaseDate: df.date(from: row.releaseDate) ?? fallbackDate,
                issueNumber: row.issueNumber,
                readStatus: ReadStatus(rawValue: row.readStatus) ?? .unread,
                priority: Priority(rawValue: row.priority) ?? .medium,
                genre: row.genre,
                notes: row.notes,
                series: row.series.isEmpty ? row.title : row.series,
                seriesLength: Int(row.seriesLength),
                rating: Double(row.rating) ?? 0.0,
                format: ComicFormat(rawValue: row.format) ?? .physical
            )
            if let lastReadAt = df.date(from: row.lastReadAt) {
                comic.lastReadAt = lastReadAt
            }
            addComic(comic, toList: mainCollection)
        }
    }

    // MARK: - Private

    private func save() {
        do {
            try modelContext.save()
        } catch {
            // handle in production
        }
    }
}
