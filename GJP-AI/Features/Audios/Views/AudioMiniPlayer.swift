import AVFoundation
import SwiftUI

struct AudioMiniPlayer: View {
    @EnvironmentObject private var app: AppModel
    let item: MediaItem
    let close: () -> Void
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var showSubtitle = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showSubtitle, let subtitle = item.subtitle, !subtitle.isEmpty {
                SafeHTMLText(html: subtitle)
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
