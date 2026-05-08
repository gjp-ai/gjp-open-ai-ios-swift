import SwiftUI

struct ImagesScreen: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var viewModel: OpenListViewModel<MediaItem>
    @State private var selectedImage: MediaItem?

    init(api: OpenAPIClient = OpenAPIClient()) {
        _viewModel = StateObject(wrappedValue: OpenListViewModel(pageSize: 50) { page, size, language, search, tags in
            try await api.images(page: page, size: size, language: language, name: search, tags: tags)
        })
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(L10n.text("images", app.language))
                .searchable(text: $viewModel.searchText, prompt: L10n.text("search", app.language))
                .toolbar { SettingsMenu() }
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

private struct ImageTile: View {
    let item: MediaItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(urlString: item.imageURL, title: item.altText ?? item.displayTitle, systemFallback: "photo")
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(item.displayTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.45))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ImagePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var app: AppModel
    let item: MediaItem

    var body: some View {
        NavigationStack {
            ScrollView {
                RemoteImage(urlString: item.url ?? item.originalUrl ?? item.imageURL, title: item.altText ?? item.displayTitle, systemFallback: "photo")
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding()
                VStack(alignment: .leading, spacing: 10) {
                    Text(item.displayTitle)
                        .font(.title3.weight(.semibold))
                    TagFlow(tags: item.tags)
                    ExternalLinkButton(titleKey: "open", urlString: item.originalUrl ?? item.url, systemImage: "safari")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle(L10n.text("images", app.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("done", app.language)) { dismiss() }
                }
            }
        }
    }
}
