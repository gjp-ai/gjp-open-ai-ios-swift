import SwiftUI

struct VideosScreen: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var viewModel: OpenListViewModel<MediaItem>
    @StateObject private var playback = VideoPlaybackController()
    @State private var showFullScreenPlayer = false

    init(api: OpenAPIClient = OpenAPIClient()) {
        _viewModel = StateObject(wrappedValue: OpenListViewModel(cacheKey: "videos", imageCache: .videos) { updatedAfter in
            try await api.allVideos(updatedAfter: updatedAfter)
        })
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(L10n.text("videos", app.language))
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $viewModel.searchText, prompt: L10n.text("search", app.language))
                .safeAreaInset(edge: .top) {
                    FilterBar(tags: app.tags("video_tags"), selectedTag: $viewModel.selectedTag, sortOrder: $viewModel.sortOrder)
                        .background(.bar)
                }
        }
        .task(id: app.language) { await viewModel.load(language: app.language) }
        .fullScreenCover(isPresented: $showFullScreenPlayer) {
            FullScreenVideoPlayer(player: playback.player) {
                showFullScreenPlayer = false
            }
        }
        .sheet(isPresented: Binding(
            get: { playback.exportedFileURL != nil },
            set: { if !$0 { playback.exportedFileURL = nil } }
        )) {
            if let fileURL = playback.exportedFileURL {
                ActivityView(activityItems: [fileURL])
            }
        }
        .alert(L10n.text("videos", app.language), isPresented: Binding(
            get: { playback.alertMessage != nil },
            set: { if !$0 { playback.alertMessage = nil } }
        )) {
            Button(L10n.text("done", app.language), role: .cancel) {}
        } message: {
            Text(playback.alertMessage ?? "")
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView(L10n.text("loading", app.language))
        case .empty:
            ContentUnavailableView(L10n.text("empty", app.language), systemImage: "play.rectangle")
        case let .error(message):
            ContentUnavailableView(L10n.text("failed", app.language), systemImage: "exclamationmark.triangle", description: Text(message))
        case .content:
            List(viewModel.items) { item in
                VideoCard(
                    playback: playback,
                    item: item,
                    items: viewModel.items,
                    fullScreen: { showFullScreenPlayer = true }
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color(.systemBackground))
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .refreshable { await viewModel.refresh() }
        }
    }
}
