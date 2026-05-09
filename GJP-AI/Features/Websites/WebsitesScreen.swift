import SwiftUI

struct WebsitesScreen: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var viewModel: OpenListViewModel<Website>

    init(api: OpenAPIClient = OpenAPIClient()) {
        _viewModel = StateObject(wrappedValue: OpenListViewModel(pageSize: 100, cacheKey: "websites") { page, size, language, search, tags in
            try await api.websites(page: page, size: size, language: language, name: search, tags: tags)
        })
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(L10n.text("websites", app.language))
                .searchable(text: $viewModel.searchText, prompt: L10n.text("search", app.language))
                .safeAreaInset(edge: .top) {
                    FilterBar(tags: app.tags("website_tags"), selectedTag: $viewModel.selectedTag, sortOrder: $viewModel.sortOrder)
                        .background(.bar)
                }
        }
        .task(id: app.language) { await viewModel.load(language: app.language) }
        .onChange(of: viewModel.searchText) { _, _ in Task { await viewModel.refresh() } }
        .onChange(of: viewModel.selectedTag) { _, _ in Task { await viewModel.refresh() } }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView(L10n.text("loading", app.language))
        case .empty:
            ContentUnavailableView(L10n.text("empty", app.language), systemImage: "globe")
        case let .error(message):
            ContentUnavailableView(L10n.text("failed", app.language), systemImage: "exclamationmark.triangle", description: Text(message))
        case .content:
            List(viewModel.items) { website in
                OpenCard {
                    WebsiteRow(website: website)
                }
                .openListCardRow()
                if website.id == viewModel.items.last?.id, viewModel.canLoadMore {
                    LoadMoreButton(isLoading: viewModel.isLoadingMore) {
                        Task { await viewModel.loadMore() }
                    }
                    .openListCardRow()
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .refreshable { await viewModel.refresh() }
        }
    }
}
