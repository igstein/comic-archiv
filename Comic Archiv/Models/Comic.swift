//
//  Comic.swift
//  Comic Archiv
//

import Foundation
import SwiftData

@Model
final class Comic {
    var id: UUID
    var titel: String
    var autor: String
    var zeichner: String
    var verlag: String
    var erscheinungsdatum: Date
    var nummer: String
    var coverBildName: String?
    var gelesen: Bool
    var erstelltAm: Date
    
    // Umgekehrte Beziehung zu Listen
    @Relationship(deleteRule: .nullify, inverse: \ComicListe.comics)
    var listen: [ComicListe]?
    // Relationship zu Reading Order Einträgen
    @Relationship(deleteRule: .nullify)
    var readingOrderEntries: [ReadingOrderEntry]?
    
    init(
        titel: String,
        autor: String = "",
        zeichner: String = "",
        verlag: String = "",
        erscheinungsdatum: Date = {
            var components = DateComponents()
            components.year = 1900
            components.month = 1
            components.day = 1
            return Calendar.current.date(from: components) ?? Date()
        }(),
        nummer: String = "",
        coverBildName: String? = nil,
        gelesen: Bool = false
    ) {
        self.id = UUID()
        self.titel = titel
        self.autor = autor
        self.zeichner = zeichner
        self.verlag = verlag
        self.erscheinungsdatum = erscheinungsdatum
        self.nummer = nummer
        self.coverBildName = coverBildName
        self.gelesen = gelesen
        self.erstelltAm = Date()
        self.listen = []
        self.readingOrderEntries = []
    }
}
