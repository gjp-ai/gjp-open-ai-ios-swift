import AVKit
import SwiftUI

struct FilterBar: View {
    @EnvironmentObject private var app: AppModel
    let tags: [String]
    @Binding var selectedTag: String?
    @Binding var sortOrder: SortOrder

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                tagButton(L10n.text("all", app.language), value: nil)
                ForEach(tags, id: \.self) { tag in
                    tagButton(tag, value: tag)
                }

                Menu {
                    ForEach(SortOrder.allCases) { order in
                        Button(L10n.text(order.rawValue, app.language)) {
                            sortOrder = order
                        }
                    }
                } label: {
                    Label(L10n.text("sort", app.language), systemImage: "line.3.horizontal.decrease")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    private func tagButton(_ title: String, value: String?) -> some View {
        Button {
            selectedTag = selectedTag == value ? nil : value
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .tint(selectedTag == value ? app.tint : Color(.secondarySystemFill))
        .foregroundStyle(selectedTag == value ? .white : .primary)
    }
}

struct StateView<Content: View>: View {
    @EnvironmentObject private var app: AppModel
    let state: ScreenState<[any OpenListItem]>
    let retry: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        switch state {
        case .loading:
            ProgressView(L10n.text("loading", app.language))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            ContentUnavailableView(L10n.text("empty", app.language), systemImage: "tray")
        case let .error(message):
            ContentUnavailableView {
                Label(L10n.text("failed", app.language), systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button(L10n.text("retry", app.language), action: retry)
                    .buttonStyle(.borderedProminent)
            }
        case .content:
            content()
        }
    }
}

struct RemoteImage: View {
    let urlString: String?
    let title: String
    let systemFallback: String

    var body: some View {
        if let urlString, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image.resizable().scaledToFill()
                case .failure:
                    fallback
                case .empty:
                    ZStack {
                        fallback.opacity(0.4)
                        ProgressView()
                    }
                @unknown default:
                    fallback
                }
            }
            .accessibilityLabel(title)
        } else {
            fallback
        }
    }

    private var fallback: some View {
        ZStack {
            Rectangle().fill(.quaternary)
            Image(systemName: systemFallback)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}

struct TagFlow: View {
    let tags: String?

    var body: some View {
        let list = tags?.tagList() ?? []
        if !list.isEmpty {
            HStack {
                ForEach(list.prefix(4), id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())
                }
            }
        }
    }
}

struct ExternalLinkButton: View {
    @EnvironmentObject private var app: AppModel
    let titleKey: String
    let urlString: String?
    let systemImage: String

    var body: some View {
        if let urlString, let url = URL(string: urlString) {
            Link(destination: url) {
                Label(L10n.text(titleKey, app.language), systemImage: systemImage)
            }
        }
    }
}

struct LoadMoreButton: View {
    @EnvironmentObject private var app: AppModel
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
            } else {
                Label(L10n.text("loadMore", app.language), systemImage: "arrow.down.circle")
            }
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct VideoPlayerView: View {
    let item: MediaItem

    var body: some View {
        if let urlString = item.url, let url = URL(string: urlString) {
            VideoPlayer(player: AVPlayer(url: url))
                .frame(minHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            ContentUnavailableView(item.displayTitle, systemImage: "video.slash")
        }
    }
}
