import SwiftUI

struct AudiosScreen: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var viewModel: OpenListViewModel<MediaItem>
    @State private var activeItem: MediaItem?

    init(api: OpenAPIClient = OpenAPIClient()) {
        _viewModel = StateObject(wrappedValue: OpenListViewModel(cacheKey: "audios", imageCache: .audios) { updatedAfter in
            try await api.allAudios(updatedAfter: updatedAfter)
        })
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(L10n.text("audios", app.language))
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $viewModel.searchText, prompt: L10n.text("search", app.language))
                .safeAreaInset(edge: .top) {
                    FilterBar(tags: app.tags("audio_tags"), selectedTag: $viewModel.selectedTag, sortOrder: $viewModel.sortOrder)
                        .background(.bar)
                }
        }
        .task(id: app.language) { await viewModel.load(language: app.language) }
        .safeAreaInset(edge: .bottom) {
            if let activeItem {
                AudioMiniPlayer(item: activeItem) {
                    self.activeItem = nil
                }
                .background(.bar)
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView(L10n.text("loading", app.language))
        case .empty:
            ContentUnavailableView(L10n.text("empty", app.language), systemImage: "music.note")
        case let .error(message):
            ContentUnavailableView(L10n.text("failed", app.language), systemImage: "exclamationmark.triangle", description: Text(message))
        case .content:
            List(viewModel.items) { item in
                Button {
                    activeItem = item
                } label: {
                    OpenCard {
                        AudioRow(item: item, isActive: activeItem?.id == item.id)
                    }
                }
                .buttonStyle(.plain)
                .openListCardRow()
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .refreshable { await viewModel.refresh() }
        }
    }
}
