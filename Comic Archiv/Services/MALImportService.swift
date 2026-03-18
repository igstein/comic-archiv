//
//  MALImportService.swift
//  Comic Archiv
//

import Foundation
import AppKit
import AuthenticationServices

// MARK: - MAL Import Service (OAuth2 PKCE + Manga List)

actor MALImportService {
    static let shared = MALImportService()
    private init() {}

    // MAL OAuth2 credentials — set your Client ID from myanimelist.net/apiconfig
    private let clientID = Secrets.malClientID

    private let authBaseURL    = "https://myanimelist.net/v1/oauth2/authorize"
    private let tokenURL       = "https://myanimelist.net/v1/oauth2/token"
    private let mangaListURL   = "https://api.myanimelist.net/v2/users/@me/mangalist"
    private let redirectURI    = "comicarchiv://callback"

    // In-memory PKCE state (valid for one auth flow)
    private var codeVerifier: String?

    // Stored access token — not sensitive enough for Keychain (short-lived)
    private var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "mal_access_token") }
        set { UserDefaults.standard.set(newValue, forKey: "mal_access_token") }
    }
    private var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: "mal_refresh_token") }
        set { UserDefaults.standard.set(newValue, forKey: "mal_refresh_token") }
    }

    // MARK: - PKCE Helpers

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .prefix(128).description
    }

    // MAL supports plain PKCE (no S256 required per their docs)
    private func codeChallenge(from verifier: String) -> String { verifier }

    // MARK: - Authorization URL

    func buildAuthURL() -> URL? {
        let verifier = generateCodeVerifier()
        codeVerifier = verifier
        let challenge = codeChallenge(from: verifier)

        var components = URLComponents(string: authBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "response_type",  value: "code"),
            URLQueryItem(name: "client_id",      value: clientID),
            URLQueryItem(name: "redirect_uri",   value: redirectURI),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "plain"),
            URLQueryItem(name: "state",          value: UUID().uuidString)
        ]
        return components?.url
    }

    // MARK: - Token Exchange

    private func exchangeCode(_ code: String) async throws {
        guard let verifier = codeVerifier else { throw MALError.missingCodeVerifier }
        guard let url = URL(string: tokenURL) else { throw MALError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "client_id":     clientID,
            "grant_type":    "authorization_code",
            "code":          code,
            "redirect_uri":  redirectURI,
            "code_verifier": verifier
        ].map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
         .joined(separator: "&")

        request.httpBody = body.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        let tokenResponse = try JSONDecoder().decode(MALTokenResponse.self, from: data)
        accessToken  = tokenResponse.accessToken
        refreshToken = tokenResponse.refreshToken
        codeVerifier = nil
    }

    // MARK: - Authorize (ASWebAuthenticationSession — handles redirect internally)

    func authorize() async throws {
        guard let url = buildAuthURL() else { throw MALError.invalidURL }

        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let helper = OAuthSessionHelper()
                let session = ASWebAuthenticationSession(
                    url: url,
                    callbackURLScheme: "comicarchiv"
                ) { callbackURL, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let callbackURL = callbackURL {
                        continuation.resume(returning: callbackURL)
                    } else {
                        continuation.resume(throwing: MALError.callbackMissingCode)
                    }
                    _ = helper  // retain until callback fires
                }
                session.presentationContextProvider = helper
                session.prefersEphemeralWebBrowserSession = false
                session.start()
            }
        }

        guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value
        else { throw MALError.callbackMissingCode }

        try await exchangeCode(code)
    }

    // MARK: - Fetch Manga List

    /// Fetches the full authenticated user's manga list from MAL.
    func fetchMangaList() async throws -> [MALMangaEntry] {
        guard let token = accessToken else { throw MALError.notAuthenticated }

        var allEntries: [MALMangaEntry] = []
        var nextURL: URL? = buildMangaListURL()

        while let url = nextURL {
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse, http.statusCode == 401 {
                throw MALError.unauthorized
            }

            let page = try JSONDecoder().decode(MALMangaListPage.self, from: data)
            allEntries.append(contentsOf: page.data)
            nextURL = page.paging.next.flatMap(URL.init)
        }

        return allEntries
    }

    private func buildMangaListURL() -> URL? {
        var components = URLComponents(string: mangaListURL)
        components?.queryItems = [
            URLQueryItem(name: "fields", value: "id,title,main_picture,status,num_volumes,num_chapters,my_list_status,authors{first_name,last_name,role},genres,start_date"),
            URLQueryItem(name: "limit",  value: "1000"),
            URLQueryItem(name: "nsfw",   value: "true")
        ]
        return components?.url
    }

    // MARK: - Logout

    func logout() {
        accessToken  = nil
        refreshToken = nil
        codeVerifier = nil
    }

    var isAuthenticated: Bool { accessToken != nil }
}

// MARK: - OAuth Presentation Helper

@MainActor
private class OAuthSessionHelper: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApplication.shared.windows.first ?? ASPresentationAnchor()
    }
}

// MARK: - Errors

enum MALError: LocalizedError {
    case invalidURL
    case callbackMissingCode
    case missingCodeVerifier
    case notAuthenticated
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid URL."
        case .callbackMissingCode:  return "OAuth callback did not contain an authorization code."
        case .missingCodeVerifier:  return "PKCE code verifier missing — start a new authorization."
        case .notAuthenticated:     return "Not authenticated. Please log in with MyAnimeList first."
        case .unauthorized:         return "Access token expired. Please log in again."
        }
    }
}

// MARK: - MAL JSON Models

private nonisolated struct MALTokenResponse: Decodable {
    let accessToken:  String
    let refreshToken: String
    let tokenType:    String
    let expiresIn:    Int
    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case tokenType    = "token_type"
        case expiresIn    = "expires_in"
    }
}

nonisolated struct MALMangaListPage: Decodable {
    let data:   [MALMangaEntry]
    let paging: MALPaging
}

nonisolated struct MALPaging: Decodable {
    let next: String?
}

nonisolated struct MALMangaEntry: Decodable, Identifiable {
    let node:         MALMangaNode
    let listStatus:   MALListStatus?

    var id: Int { node.id }

    enum CodingKeys: String, CodingKey {
        case node
        case listStatus = "list_status"
    }
}

nonisolated struct MALMangaNode: Decodable {
    let id:           Int
    let title:        String
    let mainPicture:  MALPicture?
    let authors:      [MALAuthorEdge]?
    let genres:       [MALGenre]?
    let startDate:    String?
    let numVolumes:   Int?
    let numChapters:  Int?

    enum CodingKeys: String, CodingKey {
        case id, title, authors, genres
        case mainPicture  = "main_picture"
        case startDate    = "start_date"
        case numVolumes   = "num_volumes"
        case numChapters  = "num_chapters"
    }
}

nonisolated struct MALPicture: Decodable {
    let medium: String?
    let large:  String?
}

nonisolated struct MALAuthorEdge: Decodable {
    let node: MALAuthorNode
    let role: String?
}

nonisolated struct MALAuthorNode: Decodable {
    let firstName: String?
    let lastName:  String?

    var fullName: String {
        [firstName, lastName].compactMap { $0 }.joined(separator: " ")
    }

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName  = "last_name"
    }
}

nonisolated struct MALGenre: Decodable {
    let name: String
}

nonisolated struct MALListStatus: Decodable {
    let status:         String?   // reading / completed / on_hold / dropped / plan_to_read
    let score:          Int?
    let numVolumesRead: Int?
    let numChaptersRead: Int?
    let isRereading:    Bool?

    enum CodingKeys: String, CodingKey {
        case status, score
        case numVolumesRead   = "num_volumes_read"
        case numChaptersRead  = "num_chapters_read"
        case isRereading      = "is_rereading"
    }

    var readStatus: ReadStatus {
        switch status {
        case "completed":     return .finished
        case "reading":       return .reading
        case "on_hold":       return .paused
        case "dropped":       return .abandoned
        default:              return .unread
        }
    }
}
