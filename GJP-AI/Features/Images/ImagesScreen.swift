import SwiftUI

struct ImagesScreen: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var viewModel: OpenListViewModel<MediaItem>
    @State private var selectedImage: MediaItem?

    init(api: OpenAPIClient = OpenAPIClient()) {
        _viewModel = StateObject(wrappedValue: OpenListViewModel(pageSize: 50, cacheKey: "images") { page, size, language, search, tags in
            try await api.images(page: page, size: size, language: language, name: search, tags: tags)
        })
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(L10n.text("images", app.language))
                .searchable(text: $viewModel.searchText, prompt: L10n.text("search", app.language))
                .safeAreaInset(edge: .top) {
                    FilterBar(tags: app.tags("image_tags"), selectedTag: $viewModel.selectedTag, sortOrder: $viewModel.sortOrder)
                        .background(.bar)
                }
        }
        .task(id: app.language) { await viewModel.load(language: app.language) }
        .onChange(of: viewModel.searchText) { _, _ in Task { await viewModel.refresh() } }
        .onChange(of: viewModel.selectedTag) { _, _ in Task { await viewModel.refresh() } }
        .sheet(item: $selectedImage) { item in
            ImagePreviewSheet(item: item)
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
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    ForEach(viewModel.items) { item in
                        Button {
                            selectedImage = item
                        } label: {
                            ImageTile(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                if viewModel.canLoadMore {
                    LoadMoreButton(isLoading: viewModel.isLoadingMore) {
                        Task { await viewModel.loadMore() }
                    }
                    .padding(.horizontal)
                }
            }
            .refreshable { await viewModel.refresh() }
        }
    }
}
