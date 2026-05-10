import Foundation

enum APIError: Error {
    case invalidURL
    case httpStatus(Int, String)
    case decoding(String)
    case envelope(Int, String)
}

protocol HTTPSession {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPSession {}

final class OpenAPIClient {
    static let productionBaseURL = AppConfig.API.baseURL

    private let baseURL: URL
    private let session: HTTPSession
    private let decoder: JSONDecoder

    init(baseURL: URL = OpenAPIClient.productionBaseURL, session: HTTPSession = URLSession.shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
    }

    func appSettings() async throws -> [AppSetting] {
        try await fetch("app-settings", queryItems: [])
    }

    func websites(page: Int, size: Int, language: LanguageCode, name: String?, tags: String?) async throws -> PagedData<Website> {
        try await fetchPage("websites", page: page, size: size, language: language, searchName: "name", searchValue: name, tags: tags)
    }

    func questions(page: Int, size: Int, language: LanguageCode, question: String?, tags: String?) async throws -> PagedData<Question> {
        try await fetchPage("questions", page: page, size: size, language: language, searchName: "question", searchValue: question, tags: tags)
    }

    func articles(page: Int, size: Int, language: LanguageCode, title: String?, tags: String?) async throws -> PagedData<ArticleSummary> {
        try await fetchPage("articles", page: page, size: size, language: language, searchName: "title", searchValue: title, tags: tags, extraQueryItems: [
            URLQueryItem(name: "isIncludeContent", value: "true")
        ])
    }

    func images(page: Int, size: Int, language: LanguageCode, name: String?, tags: String?) async throws -> PagedData<MediaItem> {
        try await fetchPage("images", page: page, size: size, language: language, searchName: "name", searchValue: name, tags: tags)
    }

    func videos(page: Int, size: Int, language: LanguageCode, name: String?, tags: String?) async throws -> PagedData<MediaItem> {
        try await fetchPage("videos", page: page, size: size, language: language, searchName: "name", searchValue: name, tags: tags)
    }

    func audios(page: Int, size: Int, language: LanguageCode, name: String?, tags: String?) async throws -> PagedData<MediaItem> {
        try await fetchPage("audios", page: page, size: size, language: language, searchName: "name", searchValue: name, tags: tags)
    }

    func files(page: Int, size: Int, language: LanguageCode, name: String?, tags: String?) async throws -> PagedData<FileItem> {
        try await fetchPage("files", page: page, size: size, language: language, searchName: "name", searchValue: name, tags: tags)
    }

    private func fetchPage<T: Codable>(
        _ path: String,
        page: Int,
        size: Int,
        language: LanguageCode,
        searchName: String,
        searchValue: String?,
        tags: String?,
        extraQueryItems: [URLQueryItem] = []
    ) async throws -> PagedData<T> {
        var items = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size)),
            URLQueryItem(name: "lang", value: language.rawValue),
            URLQueryItem(name: "isActive", value: "true"),
            URLQueryItem(name: "sort", value: "displayOrder"),
            URLQueryItem(name: "direction", value: "asc")
        ]
        
        items.append(contentsOf: extraQueryItems)

        if let trimmed = searchValue?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty {
            items.append(URLQueryItem(name: searchName, value: trimmed))
        }

        if let trimmedTags = tags?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmedTags.isEmpty {
            items.append(URLQueryItem(name: "tags", value: trimmedTags))
        }

        return try await fetch(path, queryItems: items)
    }

    private func fetch<T: Codable>(_ path: String, queryItems: [URLQueryItem]) async throws -> T {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        print("🌐 [API Request] \(url.absoluteString)")
        let (data, response) = try await session.data(from: url)
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 [API Response] \(jsonString)")
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpStatus(http.statusCode, text)
        }

        do {
            let envelope = try decoder.decode(ApiResponse<T>.self, from: data)
            if envelope.status.code >= 400 {
                throw APIError.envelope(envelope.status.code, envelope.status.message)
            }
            
            return envelope.data
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ [API Error] Decoding failed: \(error)")
            throw APIError.decoding(error.localizedDescription)
        }
    }
}
