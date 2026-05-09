import Foundation

enum LanguageCode: String, Codable, CaseIterable, Identifiable {
    case en = "EN"
    case zh = "ZH"

    var id: String { rawValue }
}

enum ThemeMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
}

enum AccentChoice: String, CaseIterable, Identifiable {
    case blue
    case purple
    case green
    case orange
    case red

    var id: String { rawValue }
}

struct ApiStatus: Codable, Equatable {
    let code: Int
    let message: String
    let errors: String?
}

struct ApiMeta: Codable, Equatable {
    let serverDateTime: String?
}

struct ApiResponse<T: Codable>: Codable {
    let status: ApiStatus
    let data: T
    let meta: ApiMeta?
}

struct PagedData<T: Codable>: Codable {
    let content: [T]
    let page: Int
    let size: Int
    let totalElements: Int
    let totalPages: Int
}

struct AppSetting: Codable, Identifiable, Equatable {
    var id: String { "\(name)-\(lang.rawValue)" }
    let name: String
    let value: String
    let lang: LanguageCode
}

protocol OpenListItem: Identifiable, Codable, Equatable {
    var id: String { get }
    var lang: LanguageCode { get }
    var tags: String? { get }
    var displayOrder: Int { get }
    var updatedAt: String { get }
    var searchableText: String { get }
    var sortTitle: String { get }
    /// URLs of images that should be prefetched into ImageCache when this
    /// item is restored from disk cache, so they are ready on first render.
    var imageURLsForPrefetch: [String] { get }
}

extension OpenListItem {
    var imageURLsForPrefetch: [String] { [] }
}

struct Website: OpenListItem {
    let id: String
    let name: String
    let url: String?
    let logoUrl: String?
    let description: String?
    let tags: String?
    let lang: LanguageCode
    let displayOrder: Int
    let updatedAt: String

    var searchableText: String { [name, description, tags].compactMap { $0 }.joined(separator: " ") }
    var sortTitle: String { name }
    var imageURLsForPrefetch: [String] { [logoUrl].compactMap { $0 } }
}

struct Question: OpenListItem {
    let id: String
    let question: String
    let answer: String
    let tags: String?
    let lang: LanguageCode
    let displayOrder: Int
    let updatedAt: String

    var searchableText: String { [question, answer.strippingHTML(), tags].compactMap { $0 }.joined(separator: " ") }
    var sortTitle: String { question }
}

struct ArticleSummary: OpenListItem {
    let id: String
    let title: String
    let summary: String?
    let originalUrl: String?
    let sourceName: String?
    let coverImageOriginalUrl: String?
    let coverImageUrl: String?
    let tags: String?
    let lang: LanguageCode
    let displayOrder: Int
    let updatedAt: String

    var searchableText: String { [title, summary, tags].compactMap { $0 }.joined(separator: " ") }
    var sortTitle: String { title }
    var imageURLsForPrefetch: [String] { [coverImageUrl].compactMap { $0 } }
}

struct ArticleDetail: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let summary: String?
    let originalUrl: String?
    let sourceName: String?
    let coverImageOriginalUrl: String?
    let coverImageUrl: String?
    let tags: String?
    let lang: LanguageCode
    let displayOrder: Int
    let updatedAt: String
    let content: String
    let coverImageFilename: String?
    let createdBy: String?
    let updatedBy: String?
    let isActive: Bool?
    let createdAt: String?
}

struct MediaItem: OpenListItem {
    let id: String
    let name: String?
    let title: String?
    let subtitle: String?
    let description: String?
    let url: String?
    let thumbnailUrl: String?
    let originalUrl: String?
    let coverImageUrl: String?
    let coverImageOriginalUrl: String?
    let altText: String?
    let captionsUrl: String?
    let tags: String?
    let artist: String?
    let lang: LanguageCode
    let displayOrder: Int
    let updatedAt: String

    var displayTitle: String { title ?? name ?? id }
    var imageURL: String? { thumbnailUrl ?? coverImageUrl ?? url }
    var searchableText: String { [title, name, description, artist, tags].compactMap { $0 }.joined(separator: " ") }
    var sortTitle: String { displayTitle }
    var imageURLsForPrefetch: [String] { [thumbnailUrl ?? url].compactMap { $0 } }
}

struct FileItem: OpenListItem {
    let id: String
    let name: String
    let description: String?
    let url: String?
    let originalUrl: String?
    let tags: String?
    let lang: LanguageCode
    let displayOrder: Int
    let updatedAt: String

    var searchableText: String { [name, description, tags].compactMap { $0 }.joined(separator: " ") }
    var sortTitle: String { name }
}

enum ScreenState<Value> {
    case loading
    case content(Value)
    case empty
    case error(String)
}

enum SortOrder: String, CaseIterable, Identifiable {
    case displayOrder
    case alpha
    case recent

    var id: String { rawValue }
}

extension String {
    func tagList() -> [String] {
        split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    func strippingHTML() -> String {
        replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
