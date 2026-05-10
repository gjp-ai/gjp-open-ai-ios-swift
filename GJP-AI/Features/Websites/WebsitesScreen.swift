import SafariServices
import SwiftUI

struct WebsitesScreen: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var viewModel: OpenListViewModel<Website>
    @State private var selectedWebsite: Website?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    init(api: OpenAPIClient = OpenAPIClient()) {
        _viewModel = StateObject(wrappedValue: OpenListViewModel(pageSize: AppConfig.Pagination.largePageSize, cacheKey: "websites", imageCache: .websites) { page, size, language, search, tags in
            try await api.websites(page: page, size: size, language: language, name: search, tags: tags)
        })
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(L10n.text("websites", app.language))
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $viewModel.searchText, prompt: L10n.text("search", app.language))
                .safeAreaInset(edge: .top) {
                    FilterBar(tags: app.tags("website_tags"), selectedTag: $viewModel.selectedTag, sortOrder: $viewModel.sortOrder)
                        .background(.bar)
                }
        }
        .task(id: app.language) { await viewModel.load(language: app.language) }
        .onChange(of: viewModel.searchText) { _, _ in Task { await viewModel.refresh() } }
        .onChange(of: viewModel.selectedTag) { _, _ in Task { await viewModel.refresh() } }
        .fullScreenCover(item: $selectedWebsite) { website in
            WebsiteBrowserSheet(website: website)
        }
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
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(viewModel.items) { website in
                        Button {
                            selectedWebsite = website
                        } label: {
                            WebsiteRow(website: website)
                        }
                        .buttonStyle(.plain)
                        .disabled(website.normalizedURL == nil)
                    }

                    if viewModel.canLoadMore {
                        LoadMoreButton(isLoading: viewModel.isLoadingMore) {
                            Task { await viewModel.loadMore() }
                        }
                        .gridCellColumns(2)
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 96)
            }
            .background(Color(.systemGroupedBackground))
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

private struct WebsiteBrowserSheet: View {
    @Environment(\.dismiss) private var dismiss
    let website: Website

    var body: some View {
        Group {
            if let url = website.normalizedURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            } else {
                NavigationStack {
                    ContentUnavailableView(
                        website.name,
                        systemImage: "link.badge.plus",
                        description: Text(APIError.invalidURL.localizedDescription)
                    )
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        configuration.barCollapsingEnabled = true

        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.dismissButtonStyle = .done
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
