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
        case comicVine
        case comicVineTrade
        case aniList
        case googleBooks

        var label: String {
            switch self {
            case .comicVine:      return "Issue"
            case .comicVineTrade: return "Trade"
            case .aniList:        return "AniList"
            case .googleBooks:    return "Books"
            }
        }

        var color: Color {
            switch self {
            case .comicVine:      return .blue
            case .comicVineTrade: return .indigo
            case .aniList:        return .purple
            case .googleBooks:    return .green
            }
        }
    }
}

enum CVSearchMode: Sendable {
    case issues
    case trades
}

// MARK: - Service

actor ComicSearchService {
    static let shared = ComicSearchService()
    private init() {}

    private let session = URLSession.shared

    /// Search Comic Vine and AniList in parallel and return combined results.
    func search(query: String, cvMode: CVSearchMode = .issues) async -> [ComicSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        async let cv    = cvMode == .issues ? searchComicVine(query: trimmed) : searchComicVineTrades(query: trimmed)
        async let anime = searchAniList(query: trimmed)
        async let books = searchGoogleBooks(query: trimmed)
        let (c, a, b) = await (cv, anime, books)
        return c + a + b
    }

    // MARK: - Comic Vine

    private func comicVineURL(_ path: String, params: [String: String] = [:]) -> URL? {
        let apiKey = UserDefaults.standard.string(forKey: "comicvine_api_key") ?? ""
        guard !apiKey.isEmpty else { return nil }
        var components = URLComponents(string: "https://comicvine.gamespot.com/api\(path)")
        var items = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "format",  value: "json")
        ]
        params.forEach { items.append(URLQueryItem(name: $0.key, value: $0.value)) }
        components?.queryItems = items
        return components?.url
    }

    private func comicVineRequest(url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.setValue("ComicArchiv/1.0 (personal comic manager)", forHTTPHeaderField: "User-Agent")
        return req
    }

    private func searchComicVine(query: String) async -> [ComicSearchResult] {
        guard let url = comicVineURL("/search/", params: [
            "query":      query,
            "resources":  "issue",
            "limit":      "8",
            "field_list": "id,name,issue_number,volume,cover_date,image"
        ]) else { return [] }

        do {
            let (data, _) = try await session.data(for: comicVineRequest(url: url))
            let response  = try JSONDecoder().decode(CVSearchResponse.self, from: data)
            guard response.statusCode == 1 else { return [] }
            return response.results.map(cvIssueToResult)
        } catch {
            return []
        }
    }

    private func cvIssueToResult(_ issue: CVIssueSummary) -> ComicSearchResult {
        ComicSearchResult(
            id:          "cv-\(issue.id)",
            source:      .comicVine,
            title:       issue.volume?.name ?? issue.name ?? "Unknown",
            issueNumber: issue.issueNumber ?? "",
            author:      "",
            artist:      "",
            publisher:   "",
            genre:       "",
            coverURL:    issue.image?.mediumURL.flatMap(URL.init),
            releaseDate: parseDate(issue.coverDate)
        )
    }

    /// Fetch full issue details (credits, publisher) for a Comic Vine result.
    func enrichComicVineResult(_ result: ComicSearchResult) async -> ComicSearchResult {
        guard case .comicVine = result.source,  // skip trades
              let idStr = result.id.split(separator: "-").last,
              let url = comicVineURL("/issue/4000-\(idStr)/", params: [
                  "field_list": "id,name,issue_number,volume,cover_date,image,person_credits"
              ])
        else { return result }

        do {
            let (data, _) = try await session.data(for: comicVineRequest(url: url))
            let response  = try JSONDecoder().decode(CVDetailResponse.self, from: data)
            guard response.statusCode == 1 else { return result }
            let detail = response.results

            let writers = detail.personCredits?
                .filter { $0.role.localizedCaseInsensitiveContains("writer") }
                .map(\.name).joined(separator: ", ") ?? ""

            let artists = detail.personCredits?
                .filter { $0.role.localizedCaseInsensitiveContains("penciler") || $0.role.localizedCaseInsensitiveContains("artist") }
                .map(\.name).joined(separator: ", ") ?? ""

            let publisher = detail.volume?.publisher?.name ?? result.publisher

            return ComicSearchResult(
                id:          result.id,
                source:      .comicVine,
                title:       result.title,
                issueNumber: result.issueNumber,
                author:      writers.isEmpty  ? result.author    : writers,
                artist:      artists.isEmpty  ? result.artist    : artists,
                publisher:   publisher.isEmpty ? result.publisher : publisher,
                genre:       result.genre,
                coverURL:    result.coverURL,
                releaseDate: result.releaseDate
            )
        } catch {
            return result
        }
    }

    // MARK: - Comic Vine Trades (volume-level search)

    private func searchComicVineTrades(query: String) async -> [ComicSearchResult] {
        guard let url = comicVineURL("/search/", params: [
            "query":      query,
            "resources":  "volume",
            "limit":      "8",
            "field_list": "id,name,start_year,publisher,image,count_of_issues"
        ]) else { return [] }

        do {
            let (data, _) = try await session.data(for: comicVineRequest(url: url))
            let response  = try JSONDecoder().decode(CVVolumeSearchResponse.self, from: data)
            guard response.statusCode == 1 else { return [] }
            return response.results.map(cvVolumeToResult)
        } catch {
            return []
        }
    }

    private func cvVolumeToResult(_ volume: CVVolumeResult) -> ComicSearchResult {
        var date: Date? = nil
        if let year = volume.startYear, let y = Int(year) {
            var c = DateComponents(); c.year = y; c.month = 1; c.day = 1
            date = Calendar.current.date(from: c)
        }
        return ComicSearchResult(
            id:          "cv-volume-\(volume.id)",
            source:      .comicVineTrade,
            title:       volume.name,
            issueNumber: "",
            author:      "",
            artist:      "",
            publisher:   volume.publisher?.name ?? "",
            genre:       "",
            coverURL:    volume.image?.mediumURL.flatMap(URL.init),
            releaseDate: date
        )
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

    // MARK: - Google Books

    private func searchGoogleBooks(query: String) async -> [ComicSearchResult] {
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: "8"),
            URLQueryItem(name: "printType", value: "books")
        ]
        guard let url = components?.url else { return [] }

        do {
            let (data, _) = try await session.data(for: URLRequest(url: url))
            let response = try JSONDecoder().decode(GBooksResponse.self, from: data)
            return (response.items ?? []).map(gBooksToResult)
        } catch {
            return []
        }
    }

    private func gBooksToResult(_ item: GBooksItem) -> ComicSearchResult {
        let info = item.volumeInfo

        var date: Date?
        if let dateStr = info.publishedDate {
            date = parseDate(dateStr)
        }

        let authors = info.authors?.joined(separator: ", ") ?? ""
        let genres  = info.categories?.prefix(3).joined(separator: ", ") ?? ""

        // Prefer larger thumbnail
        let coverURL: URL? = {
            if let thumb = info.imageLinks?.thumbnail {
                // Google returns http URLs; upgrade to https
                let secure = thumb.replacingOccurrences(of: "http://", with: "https://")
                return URL(string: secure)
            }
            return nil
        }()

        return ComicSearchResult(
            id:          "gbooks-\(item.id)",
            source:      .googleBooks,
            title:       info.title,
            issueNumber: "",
            author:      authors,
            artist:      "",
            publisher:   info.publisher ?? "",
            genre:       genres,
            coverURL:    coverURL,
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

// MARK: - Comic Vine JSON Models

private nonisolated struct CVSearchResponse: Decodable {
    let statusCode: Int
    let results:    [CVIssueSummary]
    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case results
    }
}

private nonisolated struct CVIssueSummary: Decodable {
    let id:          Int
    let name:        String?
    let issueNumber: String?
    let volume:      CVVolumeSummary?
    let coverDate:   String?
    let image:       CVImage?
    enum CodingKeys: String, CodingKey {
        case id, name, volume, image
        case issueNumber = "issue_number"
        case coverDate   = "cover_date"
    }
}

private nonisolated struct CVVolumeSummary: Decodable {
    let id:        Int
    let name:      String
    let publisher: CVPublisher?
}

private nonisolated struct CVPublisher: Decodable {
    let name: String
}

private nonisolated struct CVImage: Decodable {
    let mediumURL: String?
    enum CodingKeys: String, CodingKey {
        case mediumURL = "medium_url"
    }
}

private nonisolated struct CVDetailResponse: Decodable {
    let statusCode: Int
    let results:    CVIssueDetail
    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case results
    }
}

private nonisolated struct CVIssueDetail: Decodable {
    let volume:        CVVolumeSummary?
    let personCredits: [CVPerson]?
    enum CodingKeys: String, CodingKey {
        case volume
        case personCredits = "person_credits"
    }
}

private nonisolated struct CVPerson: Decodable {
    let name: String
    let role: String
}

private nonisolated struct CVVolumeSearchResponse: Decodable {
    let statusCode: Int
    let results:    [CVVolumeResult]
    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case results
    }
}

private nonisolated struct CVVolumeResult: Decodable {
    let id:            Int
    let name:          String
    let startYear:     String?
    let publisher:     CVPublisher?
    let image:         CVImage?
    let countOfIssues: Int?
    enum CodingKeys: String, CodingKey {
        case id, name, publisher, image
        case startYear     = "start_year"
        case countOfIssues = "count_of_issues"
    }
}

// MARK: - AniList JSON Models

private nonisolated struct AniListRequest: Encodable {
    let query:     String
    let variables: Variables
    struct Variables: Encodable {
        let search: String
    }
}

private nonisolated struct AniListResponse: Decodable {
    let data: AniListData
}

private nonisolated struct AniListData: Decodable {
    let Page: AniListPage
}

private nonisolated struct AniListPage: Decodable {
    let media: [AniListMedia]
}

private nonisolated struct AniListMedia: Decodable {
    let id:         Int
    let title:      AniListTitle
    let staff:      AniListStaffConnection?
    let genres:     [String]?
    let startDate:  AniListFuzzyDate?
    let coverImage: AniListCoverImage?
    let volumes:    Int?
}

private nonisolated struct AniListTitle: Decodable {
    let romaji:  String
    let english: String?
}

private nonisolated struct AniListStaffConnection: Decodable {
    let edges: [AniListStaffEdge]
}

private nonisolated struct AniListStaffEdge: Decodable {
    let role: String
    let node: AniListStaffNode
}

private nonisolated struct AniListStaffNode: Decodable {
    let name: AniListPersonName
}

private nonisolated struct AniListPersonName: Decodable {
    let full: String
}

private nonisolated struct AniListFuzzyDate: Decodable {
    let year:  Int?
    let month: Int?
    let day:   Int?
}

private nonisolated struct AniListCoverImage: Decodable {
    let large: String
}

// MARK: - Google Books JSON Models

private nonisolated struct GBooksResponse: Decodable {
    let items: [GBooksItem]?
}

private nonisolated struct GBooksItem: Decodable {
    let id: String
    let volumeInfo: GBooksVolumeInfo
}

private nonisolated struct GBooksVolumeInfo: Decodable {
    let title:         String
    let authors:       [String]?
    let publisher:     String?
    let publishedDate: String?
    let categories:    [String]?
    let imageLinks:    GBooksImageLinks?
}

private nonisolated struct GBooksImageLinks: Decodable {
    let thumbnail: String?
}
