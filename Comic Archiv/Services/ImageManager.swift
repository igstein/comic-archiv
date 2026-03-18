//
//  ImageManager.swift
//  Comic Archiv
//

import Foundation
import AppKit

class ImageManager {
    static let shared = ImageManager()
    
    private let fileManager = FileManager.default
    
    // Verzeichnis für Cover-Bilder
    private var imagesDirectory: URL {
        // Direkter Pfad zum Container Application Support
        let containerURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let imagesDir = containerURL.appendingPathComponent("CoverImages")
        
        // Erstelle Ordner falls nicht vorhanden
        if !fileManager.fileExists(atPath: imagesDir.path) {
            try? fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        }
        
        return imagesDir
    }
    
    // MARK: - Bild speichern
    
    func saveImage(_ image: NSImage) -> String? {
        // Eindeutigen Dateinamen generieren
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        // Bild in JPEG konvertieren
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            return nil
        }
        
        // Speichern
        do {
            try jpegData.write(to: fileURL)
            return fileName
        } catch {
            return nil
        }
    }
    
    // MARK: - Bild laden
    
    func loadImage(named fileName: String) -> NSImage? {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        return NSImage(contentsOf: fileURL)
    }
    
    // MARK: - Bild löschen
    
    func deleteImage(named fileName: String) {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: fileURL)
    }
    
    // MARK: - Alle Bilder löschen (für Cleanup)
    
    func deleteAllImages() {
        let fileURLs = try? fileManager.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: nil)
        fileURLs?.forEach { url in
            try? fileManager.removeItem(at: url)
        }
    }
}
