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
    
    // MARK: - Comic Operationen
    
    func addComic(_ comic: Comic, toListe liste: ComicListe? = nil) {
        modelContext.insert(comic)
        
        // Zu Liste hinzufügen falls angegeben
        if let liste = liste {
            liste.comics.append(comic)
        }
        
        save()
    }
    
    func updateComic(_ comic: Comic) {
        save()
    }
    
    func deleteComic(_ comic: Comic) {
        modelContext.delete(comic)
        save()
    }
    
    func addComicToListe(_ comic: Comic, liste: ComicListe) {
        if !liste.comics.contains(where: { $0.id == comic.id }) {
            liste.comics.append(comic)
            save()
        }
    }
    
    func removeComicFromListe(_ comic: Comic, liste: ComicListe) {
        liste.comics.removeAll(where: { $0.id == comic.id })
        save()
    }
    
    // MARK: - Listen Operationen
    
    func addListe(_ liste: ComicListe) {
        modelContext.insert(liste)
        save()
    }
    
    func updateListe(_ liste: ComicListe) {
        save()
    }
    
    func deleteListe(_ liste: ComicListe) {
        // Hauptliste kann nicht gelöscht werden
        guard !liste.istHauptliste else { return }
        
        modelContext.delete(liste)
        save()
    }
    
    // MARK: - Hilfsfunktionen
    
    private func save() {
        do {
            try modelContext.save()
        } catch {

        }
    }
    
    // MARK: - Cover-Bild Operationen
        
    func setCoverImage(_ image: NSImage, for comic: Comic) {
        // Altes Bild löschen falls vorhanden
        if let oldFileName = comic.coverBildName {
            ImageManager.shared.deleteImage(named: oldFileName)
        }
        
        // Neues Bild speichern
        if let fileName = ImageManager.shared.saveImage(image) {
            comic.coverBildName = fileName
            save()
        }
    }
    
    func removeCoverImage(from comic: Comic) {
        if let fileName = comic.coverBildName {
            ImageManager.shared.deleteImage(named: fileName)
            comic.coverBildName = nil
            save()
        }
    }
    
    func createReadingOrder(name: String, icon: String) {
        let readingOrder = ComicListe(
            name: name,
            icon: icon,
            istReadingOrder: true
        )
        modelContext.insert(readingOrder)
        try? modelContext.save()
    }
    
    // MARK: - Reading Order Operationen
    
    /// Fügt einen Comic zu einer Reading Order hinzu (immer am Ende)
    /// - Returns: true wenn erfolgreich, false wenn Comic bereits in der Liste ist
    func addComicToReadingOrder(_ comic: Comic, readingOrder: ComicListe) -> Bool {
        guard readingOrder.istReadingOrder else { return false }
        
        // Prüfen ob Comic bereits in dieser Reading Order ist
        let existingComicIDs = readingOrder.readingOrderEntries.compactMap { $0.comic?.id }
        if existingComicIDs.contains(comic.id) {
            return false // Duplikat
        }
        
        // Neue Position berechnen (am Ende)
        let newPosition = (readingOrder.readingOrderEntries.map { $0.position }.max() ?? 0) + 1
        
        // Neuen Entry erstellen
        let entry = ReadingOrderEntry(position: newPosition, comic: comic)
        entry.liste = readingOrder
        
        modelContext.insert(entry)
        save()
        
        return true
    }
    
    // MARK: - System-Listen Setup

    func ensureWishlistExists() {
        let descriptor = FetchDescriptor<ComicListe>(
            predicate: #Predicate { $0.istWishlist }
        )
        
        let existingWishlist = try? modelContext.fetch(descriptor).first
        
        if existingWishlist == nil {
            let wishlist = ComicListe(
                name: "Wishlist",
                icon: "cart",
                istWishlist: true
            )
            modelContext.insert(wishlist)
            save()
        }
    }

    func getWishlist() -> ComicListe? {
        ensureWishlistExists()
        
        let descriptor = FetchDescriptor<ComicListe>(
            predicate: #Predicate { $0.istWishlist }
        )
        
        return try? modelContext.fetch(descriptor).first
    }
    
    // MARK: - Placeholder & Wishlist Sync

    /// Erstellt einen PlaceholderComic und fügt ihn zur Wishlist hinzu
    func createPlaceholder(name: String) -> PlaceholderComic {
        // Prüfen ob Placeholder mit diesem Namen bereits existiert
        let descriptor = FetchDescriptor<PlaceholderComic>(
            predicate: #Predicate { $0.name == name }
        )
        
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        
        // Neuen Placeholder erstellen
        let placeholder = PlaceholderComic(name: name)
        modelContext.insert(placeholder)
        save()
        
        return placeholder
    }

    func convertPlaceholdersToComic(_ comic: Comic) {
        let comicTitel = comic.titel
        
        // Alle Platzhalter mit diesem Titel finden
        let descriptor = FetchDescriptor<PlaceholderComic>(
            predicate: #Predicate { $0.name == comicTitel }
        )
        
        guard let placeholders = try? modelContext.fetch(descriptor) else { return }
        
        for placeholder in placeholders {
            // Alle ReadingOrderEntries dieses Placeholders updaten
            for entry in placeholder.readingOrderEntries {
                entry.comic = comic
                entry.placeholder = nil
            }
            
            // Placeholder löschen
            modelContext.delete(placeholder)
        }
        
        save()
    }

    /// Entfernt Placeholder aus Wishlist wenn er nirgends mehr verwendet wird
    func cleanupPlaceholderIfUnused(_ placeholder: PlaceholderComic) {
        if placeholder.readingOrderEntries.isEmpty {
            modelContext.delete(placeholder)
            save()
        }
    }

    /// Gibt alle Platzhalter in der Wishlist zurück
    func getWishlistPlaceholders() -> [PlaceholderComic] {
        let descriptor = FetchDescriptor<PlaceholderComic>(
            predicate: #Predicate { $0.inWishlist == true },
            sortBy: [SortDescriptor(\.name)]
        )
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
