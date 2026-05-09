import AVFoundation
import SwiftUI

struct AudiosScreen: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var viewModel: OpenListViewModel<MediaItem>
    @State private var activeItem: MediaItem?

    init(api: OpenAPIClient = OpenAPIClient()) {
        _viewModel = StateObject(wrappedValue: OpenListViewModel(pageSize: 50) { page, size, language, search, tags in
            try await api.audios(page: page, size: size, language: language, name: search, tags: tags)
        })
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(L10n.text("audios", app.language))
                .searchable(text: $viewModel.searchText, prompt: L10n.text("search", app.language))
                .toolbar { SettingsMenu() }
                .safeAreaInset(edge: .top) {
                    FilterBar(tags: app.tags("audio_tags"), selectedTag: $viewModel.selectedTag, sortOrder: $viewModel.sortOrder)
                        .background(.bar)
                }
        }
        .task(id: app.language) { await viewModel.load(language: app.language) }
        .onChange(of: viewModel.searchText) { _, _ in Task { await viewModel.refresh() } }
        .onChange(of: viewModel.selectedTag) { _, _ in Task { await viewModel.refresh() } }
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
                if item.id == viewModel.items.last?.id, viewModel.canLoadMore {
                    LoadMoreButton(isLoading: viewModel.isLoadingMore) {
                        Task { await viewModel.loadMore() }
                    }
                    .openListCardRow()
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .refreshable { await viewModel.refresh() }
        }
    }
}

private struct AudioRow: View {
    let item: MediaItem
    let isActive: Bool

    var body: some View {
        HStack(spacing: 14) {
            RemoteImage(urlString: item.coverImageUrl, title: item.displayTitle, systemFallback: "music.note")
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 5) {
                Text(item.displayTitle)
                    .font(.headline)
                if let artist = item.artist, !artist.isEmpty {
                    Text(artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                TagFlow(tags: item.tags)
            }
            Spacer()
            Image(systemName: isActive ? "pause.circle.fill" : "play.circle.fill")
                .font(.title2)
                .foregroundStyle(.tint)
        }
    }
}

private struct AudioMiniPlayer: View {
    @EnvironmentObject private var app: AppModel
    let item: MediaItem
    let close: () -> Void
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var showSubtitle = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showSubtitle, let subtitle = item.subtitle, !subtitle.isEmpty {
                Text(HTMLText(subtitle).attributed)
                    .font(.footnote)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
            HStack(spacing: 12) {
                Button(action: toggle) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 36, height: 36)
                        .background(app.tint, in: Circle())
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading) {
                    Text(item.displayTitle)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    if let artist = item.artist {
                        Text(artist)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if item.subtitle != nil {
                    Button(L10n.text("subtitles", app.language)) {
                        showSubtitle.toggle()
                    }
                    .font(.caption.weight(.semibold))
                }
                Button(action: close) {
                    Image(systemName: "xmark.circle.fill")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .padding(.horizontal)
        .task(id: item.id) {
            if let urlString = item.url, let url = URL(string: urlString) {
                player = AVPlayer(url: url)
                player?.play()
                isPlaying = true
            }
        }
        .onDisappear {
            player?.pause()
        }
    }

    private func toggle() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }
}
