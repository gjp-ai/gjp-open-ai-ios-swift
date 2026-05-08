import SwiftUI

struct FilesScreen: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var viewModel: OpenListViewModel<FileItem>

    init(api: OpenAPIClient = OpenAPIClient()) {
        _viewModel = StateObject(wrappedValue: OpenListViewModel(pageSize: 50) { page, size, language, search, tags in
            try await api.files(page: page, size: size, language: language, name: search, tags: tags)
        })
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(L10n.text("files", app.language))
                .searchable(text: $viewModel.searchText, prompt: L10n.text("search", app.language))
                .toolbar { SettingsMenu() }
                .safeAreaInset(edge: .top) {
                    FilterBar(tags: app.tags("file_tags"), selectedTag: $viewModel.selectedTag, sortOrder: $viewModel.sortOrder)
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
            ContentUnavailableView(L10n.text("empty", app.language), systemImage: "doc")
        case let .error(message):
            ContentUnavailableView(L10n.text("failed", app.language), systemImage: "exclamationmark.triangle", description: Text(message))
        case .content:
            List(viewModel.items) { item in
                FileRow(item: item)
                if item.id == viewModel.items.last?.id, viewModel.canLoadMore {
                    LoadMoreButton(isLoading: viewModel.isLoadingMore) {
                        Task { await viewModel.loadMore() }
                    }
                }
            }
            .refreshable { await viewModel.refresh() }
        }
    }
}

private struct FileRow: View {
    @EnvironmentObject private var app: AppModel
    let item: FileItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.fill")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 44, height: 44)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)
                if let description = item.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                TagFlow(tags: item.tags)
            }
            Spacer()
            if let urlString = item.url, let url = URL(string: urlString) {
                Link(destination: url) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                }
                .accessibilityLabel("\(L10n.text("download", app.language)) \(item.name)")
            }
        }
        .padding(.vertical, 6)
    }
}
