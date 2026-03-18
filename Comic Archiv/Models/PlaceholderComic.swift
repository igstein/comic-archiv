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
    var inWishlist: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify)
    var readingOrderEntries: [ReadingOrderEntry]

    init(name: String, inWishlist: Bool = true) {
        self.id = UUID()
        self.name = name
        self.inWishlist = inWishlist
        self.createdAt = Date()
        self.readingOrderEntries = []
    }
}
