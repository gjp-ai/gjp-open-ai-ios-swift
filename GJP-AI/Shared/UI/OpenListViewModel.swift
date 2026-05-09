import Combine
import Foundation
import UIKit

@MainActor
final class OpenListViewModel<Item: OpenListItem>: ObservableObject {
    @Published private(set) var state: ScreenState<[Item]> = .loading
    @Published private(set) var totalElements = 0
    @Published private(set) var totalPages = 1
    @Published private(set) var currentPage = 0
    @Published private(set) var isLoadingMore = false
    @Published private(set) var isBackgroundRefreshing = false
    @Published private(set) var items: [Item] = []
    @Published var searchText = "" { didSet { updateFilteredItems() } }
    @Published var selectedTag: String? { didSet { updateFilteredItems() } }
    @Published var sortOrder: SortOrder = .displayOrder { didSet { updateFilteredItems() } }

    private let pageSize: Int
    private let loadPage: (Int, Int, LanguageCode, String?, String?) async throws -> PagedData<Item>
    private let cacheKey: String?
    private var currentLanguage: LanguageCode = .en
    private var rawItems: [Item] = []

    init(pageSize: Int = 50, cacheKey: String? = nil, loadPage: @escaping (Int, Int, LanguageCode, String?, String?) async throws -> PagedData<Item>) {
        self.pageSize = pageSize
        self.cacheKey = cacheKey
        self.loadPage = loadPage
    }

    private func updateFilteredItems() {
        items = filtered(rawItems)
    }

    var canLoadMore: Bool {
        currentPage + 1 < totalPages
    }

    func load(language: LanguageCode) async {
        currentLanguage = language

        // Restore from disk cache immediately so the UI shows content at once
        var hasCachedContent = false
        if let key = cacheKey, let cached: [Item] = CacheManager.load(forKey: "\(key)_\(language.rawValue)") {
            rawItems = cached
            updateFilteredItems()
            state = items.isEmpty ? .loading : .content(items)
            hasCachedContent = !items.isEmpty

            // Warm ImageCache in background for all cached items so images
            // are ready before the user scrolls (avoids loading spinners on 2nd visit)
            let urls = cached.flatMap { $0.imageURLsForPrefetch }
            ImageCache.shared.prefetch(urlStrings: urls)
        } else {
            state = .loading
        }

        // Fetch fresh data from API — silently if we already showed cache
        isBackgroundRefreshing = hasCachedContent
        await fetch(reset: true)
        isBackgroundRefreshing = false
    }

    func refresh() async {
        await fetch(reset: true)
    }

    func loadMore() async {
        guard canLoadMore, !isLoadingMore else { return }
        isLoadingMore = true
        await fetch(reset: false)
        isLoadingMore = false
    }

    private func fetch(reset: Bool) async {
        do {
            let requestedPage = reset ? 0 : currentPage + 1
            let page = try await loadPage(requestedPage, pageSize, currentLanguage, trimmedSearch, selectedTag)
            totalElements = page.totalElements
            totalPages = max(page.totalPages, 1)
            currentPage = page.page
            let languageItems = page.content.filter { $0.lang == currentLanguage }
            
            if reset {
                rawItems = languageItems
                // Save to cache on first page load
                if let key = cacheKey, trimmedSearch == nil, selectedTag == nil {
                    CacheManager.save(rawItems, forKey: "\(key)_\(currentLanguage.rawValue)")
                }
            } else {
                rawItems += languageItems
            }
            
            updateFilteredItems()
            
            if items.isEmpty {
                state = .empty
            } else {
                state = .content(items)
            }
        } catch {
            // If we already have items (from cache or previous fetch), don't show error state
            if items.isEmpty {
                state = .error(error.localizedDescription)
            } else {
                // Optionally show a subtle toast or just ignore if it's a background update failure
                print("Fetch failed, using cache/existing data: \(error)")
            }
        }
    }

    private var trimmedSearch: String? {
        let value = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func filtered(_ source: [Item]) -> [Item] {
        var result = source
        if let search = trimmedSearch?.lowercased(), !search.isEmpty {
            result = result.filter { $0.searchableText.lowercased().contains(search) }
        }
        if let selectedTag {
            result = result.filter { $0.tags?.tagList().contains(where: { $0.caseInsensitiveCompare(selectedTag) == .orderedSame }) == true }
        }

        switch sortOrder {
        case .displayOrder:
            result.sort { $0.displayOrder < $1.displayOrder }
        case .alpha:
            result.sort { $0.sortTitle.localizedCaseInsensitiveCompare($1.sortTitle) == .orderedAscending }
        case .recent:
            result.sort { $0.updatedAt > $1.updatedAt }
        }
        return result
    }
}

