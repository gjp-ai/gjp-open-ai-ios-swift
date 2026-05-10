import SwiftUI

struct ArticlesScreen: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var viewModel: OpenListViewModel<ArticleSummary>

    init(api: OpenAPIClient = OpenAPIClient()) {
        _viewModel = StateObject(wrappedValue: OpenListViewModel(cacheKey: "articles", imageCache: .articles) { updatedAfter in
            try await api.allArticles(updatedAfter: updatedAfter)
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
                        NavigationLink(value: article) {
                            ArticleRow(article: article)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 24)
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: ArticleSummary.self) { article in
                ArticleDetailScreen(article: article)
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
