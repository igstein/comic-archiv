//
//  TestData.swift
//  Comic Archiv
//

import Foundation

struct TestData {

    static let sampleComics: [Comic] = [
        Comic(title: "Spider-Man: Blue", author: "Jeph Loeb", artist: "Tim Sale",
              publisher: "Marvel", issueNumber: "1",
              readStatus: .finished, priority: .high, genre: "Superhero", series: "Spider-Man: Blue"),
        Comic(title: "Batman: Year One", author: "Frank Miller", artist: "David Mazzucchelli",
              publisher: "DC Comics", issueNumber: "1",
              readStatus: .unread, priority: .mustRead, genre: "Superhero", series: "Batman: Year One"),
        Comic(title: "Watchmen", author: "Alan Moore", artist: "Dave Gibbons",
              publisher: "DC Comics", issueNumber: "1",
              readStatus: .finished, priority: .mustRead, genre: "Superhero", series: "Watchmen"),
        Comic(title: "The Fantastic Four", author: "Stan Lee", artist: "Jack Kirby",
              publisher: "Marvel", issueNumber: "52",
              readStatus: .unread, priority: .medium, genre: "Superhero", series: "The Fantastic Four"),
        Comic(title: "Sandman", author: "Neil Gaiman", artist: "Sam Kieth",
              publisher: "DC/Vertigo", issueNumber: "1",
              readStatus: .reading, priority: .high, genre: "Fantasy", series: "Sandman")
    ]

    static func createSampleLists() -> [ComicList] {
        let mainCollection = ComicList(name: "My Collection", icon: "books.vertical.fill", isMainCollection: true)
        let marvel    = ComicList(name: "Marvel", icon: "star.fill")
        let favorites = ComicList(name: "Favorites", icon: "heart.fill")
        return [mainCollection, marvel, favorites]
    }
}
