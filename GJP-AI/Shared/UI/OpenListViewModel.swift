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
    @Published var searchText = ""
    @Published var selectedTag: String?
    @Published var sortOrder: SortOrder = .displayOrder

    private let pageSize: Int
    private let loadPage: (Int, Int, LanguageCode, String?, String?) async throws -> PagedData<Item>
    private var currentLanguage: LanguageCode = .en

    init(pageSize: Int = 50, loadPage: @escaping (Int, Int, LanguageCode, String?, String?) async throws -> PagedData<Item>) {
        self.pageSize = pageSize
        self.loadPage = loadPage
    }

    var items: [Item] {
        if case let .content(items) = state {
            return filtered(items)
        }
        return []
    }

    var canLoadMore: Bool {
        currentPage + 1 < totalPages
    }

    func load(language: LanguageCode) async {
        currentLanguage = language
        state = .loading
        await fetch(reset: true)
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
                state = languageItems.isEmpty ? .empty : .content(languageItems)
            } else if case let .content(existing) = state {
                state = .content(existing + languageItems)
            } else {
                state = languageItems.isEmpty ? .empty : .content(languageItems)
            }
        } catch {
            state = .error(error.localizedDescription)
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

struct HTMLText: Identifiable, Equatable {
    let id = UUID()
    let attributed: AttributedString

    init(_ html: String) {
        if let data = html.data(using: .utf8),
           let ns = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
           ),
           let converted = try? AttributedString(ns, including: \.uiKit) {
            attributed = converted
        } else {
            attributed = AttributedString(html.strippingHTML())
        }
    }
}
