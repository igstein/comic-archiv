//
//  TestData.swift
//  Comic Archiv
//

import Foundation

struct TestData {
    
    // Dummy Comics zum Testen
    static let dummyComics: [Comic] = [
        Comic(
            titel: "Spider-Man: Blue",
            autor: "Jeph Loeb",
            zeichner: "Tim Sale",
            verlag: "Marvel",
            nummer: "1",
            gelesen: true
        ),
        Comic(
            titel: "Batman: Year One",
            autor: "Frank Miller",
            zeichner: "David Mazzucchelli",
            verlag: "DC Comics",
            nummer: "1",
            gelesen: false
        ),
        Comic(
            titel: "Watchmen",
            autor: "Alan Moore",
            zeichner: "Dave Gibbons",
            verlag: "DC Comics",
            nummer: "1",
            gelesen: true
        ),
        Comic(
            titel: "Die Fantastischen Vier",
            autor: "Stan Lee",
            zeichner: "Jack Kirby",
            verlag: "Marvel",
            nummer: "52",
            gelesen: false
        ),
        Comic(
            titel: "Sandman",
            autor: "Neil Gaiman",
            zeichner: "Sam Kieth",
            verlag: "DC/Vertigo",
            nummer: "1",
            gelesen: true
        )
    ]
    
    // Dummy Listen zum Testen
    static func createDummyListen() -> [ComicListe] {
        let hauptliste = ComicListe(
            name: "Meine Sammlung",
            icon: "books.vertical.fill",
            istHauptliste: true
        )
        
        let gelesen = ComicListe(
            name: "Gelesen",
            icon: "checkmark.circle.fill"
        )
        
        let nochZuLesen = ComicListe(
            name: "Noch zu lesen",
            icon: "book.closed.fill"
        )
        
        let marvel = ComicListe(
            name: "Marvel",
            icon: "star.fill"
        )
        
        return [hauptliste, gelesen, nochZuLesen, marvel]
    }
}
