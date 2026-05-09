import SwiftUI

struct ArticlesScreen: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var viewModel: OpenListViewModel<ArticleSummary>
    private let api: OpenAPIClient

    init(api: OpenAPIClient = OpenAPIClient()) {
        self.api = api
        _viewModel = StateObject(wrappedValue: OpenListViewModel(pageSize: 50, cacheKey: "articles") { page, size, language, search, tags in
            try await api.articles(page: page, size: size, language: language, title: search, tags: tags)
        })
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(L10n.text("articles", app.language))
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $viewModel.searchText, prompt: L10n.text("search", app.language))
                .safeAreaInset(edge: .top) {
                    FilterBar(tags: app.tags("article_tags"), selectedTag: $viewModel.selectedTag, sortOrder: $viewModel.sortOrder)
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
            ContentUnavailableView(L10n.text("empty", app.language), systemImage: "newspaper")
        case let .error(message):
            ContentUnavailableView(L10n.text("failed", app.language), systemImage: "exclamationmark.triangle", description: Text(message))
        case .content:
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.items) { article in
                        NavigationLink(value: article.id) {
                            ArticleRow(article: article)
                        }
                        .buttonStyle(.plain)
                        
                        if article.id == viewModel.items.last?.id, viewModel.canLoadMore {
                            LoadMoreButton(isLoading: viewModel.isLoadingMore) {
                                Task { await viewModel.loadMore() }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: String.self) { id in
                ArticleDetailScreen(articleID: id, api: api)
            }
            .refreshable { await viewModel.refresh() }
            .overlay(alignment: .top) {
                if viewModel.isBackgroundRefreshing {
                    BackgroundRefreshBanner()
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isBackgroundRefreshing)
                }
            }
        }
    }
}
