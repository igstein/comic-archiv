//
//  ComicList.swift
//  Comic Archiv
//

import Foundation
import SwiftData

@Model
final class ComicList {
    var id: UUID
    var name: String
    var icon: String?
    var isMainCollection: Bool
    var isWishlist: Bool
    var isReadingOrder: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify)
    var comics: [Comic]

    @Relationship(deleteRule: .cascade)
    var readingOrderEntries: [ReadingOrderEntry]

    init(
        name: String,
        icon: String? = nil,
        isMainCollection: Bool = false,
        isWishlist: Bool = false,
        isReadingOrder: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.isMainCollection = isMainCollection
        self.isWishlist = isWishlist
        self.isReadingOrder = isReadingOrder
        self.createdAt = Date()
        self.comics = []
        self.readingOrderEntries = []
    }

    var isSystemList: Bool { isMainCollection || isWishlist }

    var readingProgress: (read: Int, total: Int, toBuy: Int)? {
        guard isReadingOrder else { return nil }
        let total = readingOrderEntries.count
        let read  = readingOrderEntries.filter { $0.comic?.readStatus == .finished }.count
        let toBuy = readingOrderEntries.filter { $0.comic == nil }.count
        return (read: read, total: total, toBuy: toBuy)
    }

    var sortedReadingOrderEntries: [ReadingOrderEntry] {
        readingOrderEntries.sorted { $0.position < $1.position }
    }
}
