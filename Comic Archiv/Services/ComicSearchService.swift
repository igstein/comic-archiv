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
        case aniList

        var label: String {
            switch self {
            case .comicVine: return "Comic Vine"
            case .aniList:   return "AniList"
            }
        }

        var color: Color {
            switch self {
            case .comicVine: return .blue
            case .aniList:   return .purple
            }
        }
    }
}

// MARK: - Service

actor ComicSearchService {
    static let shared = ComicSearchService()
    private init() {}

    private let session = URLSession.shared

    /// Search Comic Vine and AniList in parallel and return combined results.
    func search(query: String) async -> [ComicSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        async let cv    = searchComicVine(query: trimmed)
        async let anime = searchAniList(query: trimmed)
        let (c, a) = await (cv, anime)
        return c + a
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
        guard case .comicVine = result.source,
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
