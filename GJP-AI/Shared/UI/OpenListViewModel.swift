import Combine
import Foundation
import UIKit

@MainActor
final class OpenListViewModel<Item: OpenListItem>: ObservableObject {
    @Published private(set) var state: ScreenState<[Item]> = .loading
    @Published private(set) var totalElements = 0
    @Published private(set) var isBackgroundRefreshing = false
    @Published private(set) var items: [Item] = []
    @Published var searchText = "" { didSet { updateFilteredItems() } }
    @Published var selectedTag: String? { didSet { updateFilteredItems() } }
    @Published var sortOrder: SortOrder = .displayOrder { didSet { updateFilteredItems() } }

    private let loadAll: (String?) async throws -> [Item]
    private let cacheKey: String
    private let contentStore: SQLiteContentStore<Item>
    private let imageCache: MediaCache
    private var currentLanguage: LanguageCode = .en
 
    init(cacheKey: String, imageCache: MediaCache? = nil, loadAll: @escaping (String?) async throws -> [Item]) {
        self.cacheKey = cacheKey
        self.contentStore = SQLiteContentStore(key: cacheKey)
        self.imageCache = imageCache ?? .media
        self.loadAll = loadAll
    }
 
    private func updateFilteredItems() {
        items = contentStore.query(
            language: currentLanguage,
            search: trimmedSearch,
            tag: selectedTag,
            sortOrder: sortOrder
        )
        totalElements = items.count
        state = items.isEmpty ? .empty : .content(items)
    }
 
    func load(language: LanguageCode) async {
        currentLanguage = language
        updateFilteredItems()
        
        let cachedCount = contentStore.count(language: currentLanguage)
        let lastSync = contentStore.lastModified(language: currentLanguage)
        let isCacheFresh = lastSync.map { Date().timeIntervalSince($0) < AppConfig.Cache.listFreshnessDuration } ?? false

        if cachedCount == 0 {
            state = .loading
        } else {
            let urls = items.flatMap { $0.imageURLsForPrefetch }
            imageCache.prefetch(urlStrings: urls)
        }

        if !isCacheFresh {
            isBackgroundRefreshing = cachedCount > 0
            await syncAllFromAPI()
            isBackgroundRefreshing = false
        }
    }

    func refresh() async {
        await syncAllFromAPI()
    }

    private func syncAllFromAPI() async {
        do {
            let updatedAfter = contentStore.updatedAfter(language: currentLanguage)
            let apiCallTime = SQLiteContentDatabase.syncDateString(from: Date())
            let fetched = try await loadAll(updatedAfter)
            contentStore.save(
                fetched,
                language: currentLanguage,
                replaceExisting: updatedAfter == nil,
                successfulSyncDate: apiCallTime
            )
            updateFilteredItems()
            let urls = fetched.flatMap { $0.imageURLsForPrefetch }
            imageCache.prefetch(urlStrings: urls)
        } catch {
            if items.isEmpty {
                state = .error(error.localizedDescription)
            } else {
                print("Full sync failed, using local database: \(error)")
            }
        }
    }

    private var trimmedSearch: String? {
        let value = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
