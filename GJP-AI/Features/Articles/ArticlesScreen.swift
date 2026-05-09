import SwiftUI

struct ArticlesScreen: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var viewModel: OpenListViewModel<ArticleSummary>
    private let api: OpenAPIClient

    init(api: OpenAPIClient = OpenAPIClient()) {
        self.api = api
        _viewModel = StateObject(wrappedValue: OpenListViewModel(pageSize: 50) { page, size, language, search, tags in
            try await api.articles(page: page, size: size, language: language, title: search, tags: tags)
        })
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(L10n.text("articles", app.language))
                .searchable(text: $viewModel.searchText, prompt: L10n.text("search", app.language))
                .toolbar { SettingsMenu() }
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
            List(viewModel.items) { article in
                NavigationLink(value: article.id) {
                    OpenCard {
                        ArticleRow(article: article)
                    }
                }
                .openListCardRow()
                if article.id == viewModel.items.last?.id, viewModel.canLoadMore {
                    LoadMoreButton(isLoading: viewModel.isLoadingMore) {
                        Task { await viewModel.loadMore() }
                    }
                    .openListCardRow()
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: String.self) { id in
                ArticleDetailScreen(articleID: id, api: api)
            }
            .refreshable { await viewModel.refresh() }
        }
    }
}

private struct ArticleRow: View {
    let article: ArticleSummary

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RemoteImage(urlString: article.coverImageUrl, title: article.title, systemFallback: "newspaper")
                .frame(width: 92, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                if let summary = article.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                HStack {
                    TagFlow(tags: article.tags)
                    Spacer()
                    Text(article.updatedAt.prefix(10))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct ArticleDetailScreen: View {
    @EnvironmentObject private var app: AppModel
    let articleID: String
    let api: OpenAPIClient
    @State private var state: ScreenState<ArticleDetail> = .loading
    @State private var showCover = true

    var body: some View {
        ScrollView {
            switch state {
            case .loading:
                ProgressView(L10n.text("loading", app.language))
                    .padding()
            case let .error(message):
                ContentUnavailableView(L10n.text("failed", app.language), systemImage: "exclamationmark.triangle", description: Text(message))
            case .empty:
                ContentUnavailableView(L10n.text("empty", app.language), systemImage: "newspaper")
            case let .content(article):
                VStack(alignment: .leading, spacing: 18) {
                    if showCover, article.coverImageUrl != nil {
                        RemoteImage(urlString: article.coverImageUrl, title: article.title, systemFallback: "newspaper")
                            .frame(maxWidth: .infinity)
                            .frame(height: 230)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    Text(HTMLText(article.content).attributed)
                        .textSelection(.enabled)
                    HStack {
                        ExternalLinkButton(titleKey: "original", urlString: article.originalUrl, systemImage: "safari")
                        Spacer()
                        if article.coverImageUrl != nil {
                            Button {
                                showCover.toggle()
                            } label: {
                                Image(systemName: showCover ? "photo" : "photo.slash")
                            }
                        }
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        if let source = article.sourceName, !source.isEmpty {
                            Label(source, systemImage: "building.2")
                        }
                        if let tags = article.tags, !tags.isEmpty {
                            Label(tags, systemImage: "tag")
                        }
                        Label(String(article.updatedAt.prefix(10)), systemImage: "calendar")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: articleID) { await load() }
    }

    private func load() async {
        state = .loading
        do {
            state = .content(try await api.article(id: articleID))
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
