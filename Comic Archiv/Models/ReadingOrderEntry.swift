//
//  ReadingOrderEntry.swift
//  Comic Archiv
//

import Foundation
import SwiftData

@Model
final class ReadingOrderEntry {
    var id: UUID
    var position: Int

    @Relationship(deleteRule: .nullify, inverse: \Comic.readingOrderEntries)
    var comic: Comic?

    @Relationship(deleteRule: .nullify, inverse: \PlaceholderComic.readingOrderEntries)
    var placeholder: PlaceholderComic?

    var placeholderName: String?
    var note: String?
    var createdAt: Date

    @Relationship(inverse: \ComicList.readingOrderEntries)
    var list: ComicList?

    init(position: Int, comic: Comic) {
        self.id = UUID()
        self.position = position
        self.comic = comic
        self.placeholderName = nil
        self.note = nil
        self.createdAt = Date()
    }

    init(position: Int, placeholder: PlaceholderComic) {
        self.id = UUID()
        self.position = position
        self.comic = nil
        self.placeholder = placeholder
        self.placeholderName = nil
        self.note = nil
        self.createdAt = Date()
    }

    init(position: Int, placeholderName: String) {
        self.id = UUID()
        self.position = position
        self.comic = nil
        self.placeholderName = placeholderName
        self.note = nil
        self.createdAt = Date()
    }

    var isPlaceholder: Bool {
        comic == nil && (placeholder != nil || placeholderName != nil)
    }

    var displayName: String {
        comic?.title ?? placeholder?.name ?? placeholderName ?? "Unknown"
    }
}
