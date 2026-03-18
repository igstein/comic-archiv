//
//  ComicSearchService.swift
//  Comic Archiv
//

import Foundation
import SwiftUI

// MARK: - Unified Result

struct ComicSearchResult: Identifiable, Sendable {
    let id: String
    let source: SearchSource
    let title: String
    let issueNumber: String
    let author: String
    let artist: String
    let publisher: String
    let genre: String
    let coverURL: URL?
    let releaseDate: Date?

    enum SearchSource: Sendable {
        case metron
        case aniList

        var label: String {
            switch self {
            case .metron:  return "Metron"
            case .aniList: return "AniList"
            }
        }

        var color: Color {
            switch self {
            case .metron:  return .blue
            case .aniList: return .purple
            }
        }
    }
}

// MARK: - Service

actor ComicSearchService {
    static let shared = ComicSearchService()
    private init() {}

    private let session = URLSession.shared

    /// Search both Metron and AniList in parallel and return combined results.
    func search(query: String) async -> [ComicSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        async let metron  = searchMetron(query: trimmed)
        async let aniList = searchAniList(query: trimmed)
        let (m, a) = await (metron, aniList)
        return m + a
    }

    // MARK: - Metron

    private func metronRequest(for url: URL) -> URLRequest? {
        guard let username = KeychainHelper.metronUsername,
              let password = KeychainHelper.metronPassword,
              !username.isEmpty, !password.isEmpty else { return nil }
        var req = URLRequest(url: url)
        let token = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
        req.setValue("Basic \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("ComicArchiv/1.0 (personal comic manager)", forHTTPHeaderField: "User-Agent")
        return req
    }

    private func searchMetron(query: String) async -> [ComicSearchResult] {
        guard
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "https://metron.cloud/api/issue/?series_name=\(encoded)&page_size=8"),
            let request = metronRequest(for: url)
        else { return [] }

        do {
            let (data, _) = try await session.data(for: request)
            let response  = try JSONDecoder().decode(MetronListResponse.self, from: data)
            return response.results.map(metronSummaryToResult)
        } catch {
            return []
        }
    }

    private func metronSummaryToResult(_ issue: MetronIssueSummary) -> ComicSearchResult {
        ComicSearchResult(
            id:          "metron-\(issue.id)",
            source:      .metron,
            title:       issue.series.name,
            issueNumber: issue.number,
            author:      "",
            artist:      "",
            publisher:   issue.publisher.name,
            genre:       issue.genres.first?.name ?? "",
            coverURL:    issue.image.flatMap(URL.init),
            releaseDate: parseDate(issue.coverDate)
        )
    }

    /// Fetch full issue details (credits/creators) for a Metron result.
    func enrichMetronResult(_ result: ComicSearchResult) async -> ComicSearchResult {
        guard
            case .metron = result.source,
            let idStr  = result.id.split(separator: "-").last,
            let issueID = Int(idStr),
            let url    = URL(string: "https://metron.cloud/api/issue/\(issueID)/"),
            let request = metronRequest(for: url)
        else { return result }

        do {
            let (data, _) = try await session.data(for: request)
            let detail    = try JSONDecoder().decode(MetronIssueDetail.self, from: data)

            let writers = detail.credits
                .filter { $0.role.contains { $0.name.localizedCaseInsensitiveContains("writer") || $0.name.localizedCaseInsensitiveContains("script") } }
                .map(\.creator).joined(separator: ", ")

            let artists = detail.credits
                .filter { $0.role.contains { $0.name.localizedCaseInsensitiveContains("pencill") || $0.name.localizedCaseInsensitiveContains("artist") } }
                .map(\.creator).joined(separator: ", ")

            let genres = detail.genres.map(\.name).joined(separator: ", ")

            return ComicSearchResult(
                id:          result.id,
                source:      .metron,
                title:       result.title,
                issueNumber: result.issueNumber,
                author:      writers.isEmpty  ? result.author    : writers,
                artist:      artists.isEmpty  ? result.artist    : artists,
                publisher:   result.publisher,
                genre:       genres.isEmpty   ? result.genre     : genres,
                coverURL:    result.coverURL,
                releaseDate: result.releaseDate
            )
        } catch {
            return result
        }
    }

    // MARK: - AniList

    private func searchAniList(query: String) async -> [ComicSearchResult] {
        guard let url = URL(string: "https://graphql.anilist.co") else { return [] }

        let body = AniListRequest(
            query: aniListQuery,
            variables: AniListRequest.Variables(search: query)
        )
        guard let bodyData = try? JSONEncoder().encode(body) else { return [] }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        do {
            let (data, _) = try await session.data(for: request)
            let response  = try JSONDecoder().decode(AniListResponse.self, from: data)
            return response.data.Page.media.map(aniListMediaToResult)
        } catch {
            return []
        }
    }

    private func aniListMediaToResult(_ media: AniListMedia) -> ComicSearchResult {
        let title  = media.title.english ?? media.title.romaji

        let author = media.staff?.edges
            .first { $0.role.contains("Story") }?
            .node.name.full ?? ""

        let artist = media.staff?.edges
            .first { $0.role == "Art" || ($0.role.contains("Art") && !$0.role.contains("Story")) }?
            .node.name.full ?? ""

        let genres = media.genres?.prefix(3).joined(separator: ", ") ?? ""

        var date: Date?
        if let year = media.startDate?.year {
            var c = DateComponents()
            c.year  = year
            c.month = media.startDate?.month ?? 1
            c.day   = media.startDate?.day   ?? 1
            date = Calendar.current.date(from: c)
        }

        let volStr = media.volumes.map { "Vol. \($0)" } ?? ""

        return ComicSearchResult(
            id:          "anilist-\(media.id)",
            source:      .aniList,
            title:       title,
            issueNumber: volStr,
            author:      author,
            artist:      artist,
            publisher:   "",
            genre:       genres,
            coverURL:    media.coverImage.flatMap { URL(string: $0.large) },
            releaseDate: date
        )
    }

    // MARK: - Helpers

    private func parseDate(_ str: String?) -> Date? {
        guard let s = str else { return nil }
        let formatter = DateFormatter()
        for fmt in ["yyyy-MM-dd", "yyyy-MM", "yyyy"] {
            formatter.dateFormat = fmt
            if let d = formatter.date(from: s) { return d }
        }
        return nil
    }

    private let aniListQuery = """
    query ($search: String) {
        Page(page: 1, perPage: 8) {
            media(search: $search, type: MANGA, sort: SEARCH_MATCH) {
                id
                title { romaji english }
                staff(sort: RELEVANCE, perPage: 6) {
                    edges { role node { name { full } } }
                }
                genres
                startDate { year month day }
                coverImage { large }
                volumes
            }
        }
    }
    """
}

// MARK: - Metron JSON Models

private struct MetronListResponse: Codable {
    let results: [MetronIssueSummary]
}

private struct MetronIssueSummary: Codable {
    let id:        Int
    let publisher: MetronNamedItem
    let series:    MetronNamedItem
    let number:    String
    let coverDate: String?
    let image:     String?
    let genres:    [MetronNamedItem]

    enum CodingKeys: String, CodingKey {
        case id, publisher, series, number, image, genres
        case coverDate = "cover_date"
    }
}

private struct MetronIssueDetail: Codable {
    let genres:  [MetronNamedItem]
    let credits: [MetronCredit]
}

private struct MetronCredit: Codable {
    let creator: String
    let role:    [MetronNamedItem]
}

private struct MetronNamedItem: Codable {
    let id:   Int
    let name: String
}

// MARK: - AniList JSON Models

private struct AniListRequest: Encodable {
    let query:     String
    let variables: Variables

    struct Variables: Encodable {
        let search: String
    }
}

private struct AniListResponse: Decodable {
    let data: AniListData
}

private struct AniListData: Decodable {
    let Page: AniListPage
}

private struct AniListPage: Decodable {
    let media: [AniListMedia]
}

private struct AniListMedia: Decodable {
    let id:         Int
    let title:      AniListTitle
    let staff:      AniListStaffConnection?
    let genres:     [String]?
    let startDate:  AniListFuzzyDate?
    let coverImage: AniListCoverImage?
    let volumes:    Int?
}

private struct AniListTitle: Decodable {
    let romaji:  String
    let english: String?
}

private struct AniListStaffConnection: Decodable {
    let edges: [AniListStaffEdge]
}

private struct AniListStaffEdge: Decodable {
    let role: String
    let node: AniListStaffNode
}

private struct AniListStaffNode: Decodable {
    let name: AniListPersonName
}

private struct AniListPersonName: Decodable {
    let full: String
}

private struct AniListFuzzyDate: Decodable {
    let year:  Int?
    let month: Int?
    let day:   Int?
}

private struct AniListCoverImage: Decodable {
    let large: String
}
