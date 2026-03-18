//
//  ComicListe.swift
//  Comic Archiv
//

import Foundation
import SwiftData

@Model
final class ComicListe {
    var id: UUID
    var name: String
    var icon: String?
    var istHauptliste: Bool
    var istWishlist: Bool
    var erstelltAm: Date
    var istReadingOrder: Bool
    
    // Beziehung zu Comics - Viele-zu-Viele
    @Relationship(deleteRule: .nullify)
    var comics: [Comic]
    
    @Relationship(deleteRule: .cascade)
    var readingOrderEntries: [ReadingOrderEntry]
    
    init(
        name: String,
        icon: String? = nil,
        istHauptliste: Bool = false,
        istWishlist: Bool = false,
        istReadingOrder: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.istHauptliste = istHauptliste
        self.istWishlist = istWishlist
        self.erstelltAm = Date()
        self.istReadingOrder = istReadingOrder
        self.comics = []
        self.readingOrderEntries = []
    }
    
    var isSystemList: Bool {
            istHauptliste || istWishlist
    }
    
    var readingProgress: (gelesen: Int, gesamt: Int, zuKaufen: Int)? {
            guard istReadingOrder else { return nil }
            
            let gesamt = readingOrderEntries.count
            let gelesen = readingOrderEntries.filter { entry in
                entry.comic?.gelesen == true
            }.count
            let zuKaufen = readingOrderEntries.filter { entry in
                entry.comic == nil
            }.count
            
            return (gelesen: gelesen, gesamt: gesamt, zuKaufen: zuKaufen)
        }
        
        var sortedReadingOrderEntries: [ReadingOrderEntry] {
            readingOrderEntries.sorted { $0.position < $1.position }
        }
}
