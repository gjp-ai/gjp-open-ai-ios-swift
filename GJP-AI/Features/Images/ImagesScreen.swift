import SwiftUI

struct ImagesScreen: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var viewModel: OpenListViewModel<MediaItem>
    @State private var selectedImage: MediaItem?

    init(api: OpenAPIClient = OpenAPIClient()) {
        _viewModel = StateObject(wrappedValue: OpenListViewModel(cacheKey: "images", imageCache: .media) { updatedAfter in
            try await api.allImages(updatedAfter: updatedAfter)
        })
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(L10n.text("images", app.language))
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $viewModel.searchText, prompt: L10n.text("search", app.language))
                .safeAreaInset(edge: .top) {
                    FilterBar(tags: app.tags("image_tags"), selectedTag: $viewModel.selectedTag, sortOrder: $viewModel.sortOrder)
                        .background(.bar)
                }
        }
        .task(id: app.language) { await viewModel.load(language: app.language) }
        .sheet(item: $selectedImage) { item in
            ImagePreviewSheet(item: item, items: viewModel.items)
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView(L10n.text("loading", app.language))
        case .empty:
            ContentUnavailableView(L10n.text("empty", app.language), systemImage: "photo")
        case let .error(message):
            ContentUnavailableView(L10n.text("failed", app.language), systemImage: "exclamationmark.triangle", description: Text(message))
        case .content:
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(viewModel.items) { item in
                        Button {
                            selectedImage = item
                        } label: {
                            ImageTile(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
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
