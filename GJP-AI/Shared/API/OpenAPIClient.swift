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
    private static let channel = "AI"

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


    func allWebsites(updatedAfter: String?) async throws -> [Website] {
        try await fetchAll("websites/all", updatedAfter: updatedAfter)
    }


    func allQuestions(updatedAfter: String?) async throws -> [Question] {
        try await fetchAll("questions/all", updatedAfter: updatedAfter)
    }


    func allArticles(updatedAfter: String?) async throws -> [ArticleSummary] {
        try await fetchAll("articles/all", updatedAfter: updatedAfter)
    }


    func allImages(updatedAfter: String?) async throws -> [MediaItem] {
        try await fetchAll("images/all", updatedAfter: updatedAfter)
    }

    func allVideos(updatedAfter: String?) async throws -> [MediaItem] {
        try await fetchAll("videos/all", updatedAfter: updatedAfter)
    }

    func allAudios(updatedAfter: String?) async throws -> [MediaItem] {
        try await fetchAll("audios/all", updatedAfter: updatedAfter)
    }

    func allFiles(updatedAfter: String?) async throws -> [FileItem] {
        try await fetchAll("files/all", updatedAfter: updatedAfter)
    }

    private func fetchAll<T: Codable>(_ path: String, updatedAfter: String?) async throws -> [T] {
        var items = [
            URLQueryItem(name: "isActive", value: "true")
        ]
        if let updatedAfter {
            items.append(URLQueryItem(name: "updatedAfter", value: updatedAfter))
        }
        return try await fetch(path, queryItems: items)
    }

    private func fetch<T: Codable>(_ path: String, queryItems: [URLQueryItem]) async throws -> T {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "channel", value: Self.channel)] + queryItems.filter { $0.name != "channel" }

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
