//
//  PlaceholderComic.swift
//  Comic Archiv
//

import Foundation
import SwiftData

@Model
final class PlaceholderComic {
    var id: UUID
    var name: String
    var erstelltAm: Date
    
    // Beziehung zu Reading Order Einträgen
    // Ein Platzhalter kann in mehreren Reading Orders vorkommen
    @Relationship(deleteRule: .nullify)
    var readingOrderEntries: [ReadingOrderEntry]
    
    // Wishlist-Status (true = soll gekauft werden)
    var inWishlist: Bool
    
    init(name: String, inWishlist: Bool = true) {
        self.id = UUID()
        self.name = name
        self.erstelltAm = Date()
        self.inWishlist = inWishlist
        self.readingOrderEntries = []
    }
}
