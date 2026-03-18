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
    var notiz: String?
    var erstelltAm: Date
    
    // Hier definieren wir die inverse Beziehung
    @Relationship(inverse: \ComicListe.readingOrderEntries)
    var liste: ComicListe?
    
    // Mit Comic
    init(position: Int, comic: Comic) {
        self.id = UUID()
        self.position = position
        self.comic = comic
        self.placeholderName = nil
        self.notiz = nil
        self.erstelltAm = Date()
    }
    
    // Mit PlaceholderComic
    init(position: Int, placeholder: PlaceholderComic) {
        self.id = UUID()
        self.position = position
        self.comic = nil
        self.placeholder = placeholder
        self.placeholderName = nil
        self.notiz = nil
        self.erstelltAm = Date()
    }
    
    // Platzhalter
    init(position: Int, placeholderName: String) {
        self.id = UUID()
        self.position = position
        self.comic = nil
        self.placeholderName = placeholderName
        self.notiz = nil
        self.erstelltAm = Date()
    }
    
    var isPlaceholder: Bool {
        comic == nil && (placeholder != nil || placeholderName != nil)
    }
    
    var displayName: String {
        comic?.titel ?? placeholder?.name ?? placeholderName ?? "Unbekannt"
    }
}
