import SwiftUI

struct VideoCard: View {
    @EnvironmentObject private var app: AppModel
    @ObservedObject var playback: VideoPlaybackController
    let item: MediaItem
    let items: [MediaItem]
    let fullScreen: () -> Void

    private var isCurrent: Bool {
        playback.currentItem == item
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            videoSurface
            metadataRow
        }
        .padding(.bottom, 18)
        .background(Color(.systemBackground))
    }

    @ViewBuilder private var videoSurface: some View {
        if isCurrent {
            VideoPlayerView(player: playback.player)
                .transition(.opacity)
        } else {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    playback.play(item, in: items)
                }
            } label: {
                ZStack {
                    RemoteImage(
                        urlString: item.coverImageUrl ?? item.thumbnailUrl,
                        title: item.displayTitle,
                        systemFallback: "play.rectangle"
                    )
                    .aspectRatio(16 / 9, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .clipped()

                    LinearGradient(
                        colors: [.black.opacity(0.45), .black.opacity(0.05), .black.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
                }
                .aspectRatio(16 / 9, contentMode: .fit)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var metadataRow: some View {
        HStack(alignment: .top, spacing: 12) {
            channelAvatar

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)

                Text(metadataText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 6)
            if isCurrent {
                Button(action: fullScreen) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 32, height: 32)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.text("fullScreen", app.language))
            }
            downloadMenu
        }
        .padding(.horizontal, 12)
    }

    private var channelAvatar: some View {
        ZStack {
            Circle()
                .fill(app.tint.gradient)
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 38, height: 38)
        .accessibilityHidden(true)
    }

    private var downloadMenu: some View {
        Menu {
            Button {
                playback.prepareFileExport(for: item)
            } label: {
                Label(L10n.text("saveToFiles", app.language), systemImage: "folder")
            }
            Button {
                playback.saveToPhotos(item)
            } label: {
                Label(L10n.text("saveToPhotos", app.language), systemImage: "photo")
            }
        } label: {
            if playback.isDownloading {
                ProgressView()
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "ellipsis")
                    .font(.headline.weight(.semibold))
                    .rotationEffect(.degrees(90))
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.primary)
            }
        }
        .disabled(playback.isDownloading)
    }

    private var metadataText: String {
        let owner = item.artist ?? "GJP AI"
        let description = item.description?.strippingHTML()
        if let description, !description.isEmpty {
            return "\(owner) • \(description)"
        }
        return owner
    }
}
