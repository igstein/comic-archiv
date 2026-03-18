//
//  Comic.swift
//  Comic Archiv
//

import Foundation
import SwiftData

enum ReadStatus: String, Codable, CaseIterable {
    case unread    = "unread"
    case reading   = "reading"
    case paused    = "paused"
    case finished  = "finished"
    case abandoned = "abandoned"

    var label: String {
        switch self {
        case .unread:    return "Unread"
        case .reading:   return "Reading"
        case .paused:    return "Paused"
        case .finished:  return "Finished"
        case .abandoned: return "Abandoned"
        }
    }

    var icon: String {
        switch self {
        case .unread:    return "book.closed"
        case .reading:   return "book"
        case .paused:    return "pause.circle"
        case .finished:  return "checkmark.circle.fill"
        case .abandoned: return "xmark.circle"
        }
    }
}

enum Priority: String, Codable, CaseIterable {
    case mustRead = "mustRead"
    case high     = "high"
    case medium   = "medium"
    case low      = "low"

    var label: String {
        switch self {
        case .mustRead: return "Must Read"
        case .high:     return "High"
        case .medium:   return "Medium"
        case .low:      return "Low"
        }
    }

    var icon: String {
        switch self {
        case .mustRead: return "star.fill"
        case .high:     return "circle.fill"
        case .medium:   return "circle.fill"
        case .low:      return "circle"
        }
    }

    var sortOrder: Int {
        switch self {
        case .mustRead: return 0
        case .high:     return 1
        case .medium:   return 2
        case .low:      return 3
        }
    }
}

@Model
final class Comic {
    var id: UUID
    var title: String
    var author: String
    var artist: String
    var publisher: String
    var releaseDate: Date
    var issueNumber: String
    var coverImageName: String?
    var readStatus: ReadStatus
    var priority: Priority
    var genre: String
    var notes: String
    var lastReadAt: Date?
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \ComicList.comics)
    var lists: [ComicList]?

    @Relationship(deleteRule: .nullify)
    var readingOrderEntries: [ReadingOrderEntry]?

    var isRead: Bool { readStatus == .finished }

    init(
        title: String,
        author: String = "",
        artist: String = "",
        publisher: String = "",
        releaseDate: Date = {
            var c = DateComponents(); c.year = 1900; c.month = 1; c.day = 1
            return Calendar.current.date(from: c) ?? Date()
        }(),
        issueNumber: String = "",
        coverImageName: String? = nil,
        readStatus: ReadStatus = .unread,
        priority: Priority = .medium,
        genre: String = "",
        notes: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.artist = artist
        self.publisher = publisher
        self.releaseDate = releaseDate
        self.issueNumber = issueNumber
        self.coverImageName = coverImageName
        self.readStatus = readStatus
        self.priority = priority
        self.genre = genre
        self.notes = notes
        self.lastReadAt = nil
        self.createdAt = Date()
        self.lists = []
        self.readingOrderEntries = []
    }
}
