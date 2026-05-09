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
        VStack(spacing: 0) {
            // Top accent line
            app.tint
                .frame(height: 2)
                .opacity(0.6)

            VStack(alignment: .leading, spacing: 10) {
                if showSubtitle, let subtitle = item.subtitle, !subtitle.isEmpty {
                    SafeHTMLText(html: subtitle)
                        .font(.footnote)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                HStack(spacing: 12) {
                    Button(action: toggle) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.subheadline.weight(.bold))
                            .frame(width: 40, height: 40)
                            .background(app.tint.gradient, in: Circle())
                            .foregroundStyle(.white)
                            .shadow(color: app.tint.opacity(0.35), radius: 6, y: 2)
                    }
                    VStack(alignment: .leading, spacing: 2) {
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
                        Button {
                            withAnimation(.spring(response: 0.35)) {
                                showSubtitle.toggle()
                            }
                        } label: {
                            Image(systemName: "captions.bubble")
                                .font(.body)
                                .foregroundStyle(showSubtitle ? app.tint : .secondary)
                        }
                    }
                    Button(action: close) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 0))
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
