import SwiftUI

struct VideoCard: View {
    let item: MediaItem
    @State private var showPlayer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showPlayer {
                VideoPlayerView(item: item)
                    .transition(.opacity)
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showPlayer = true
                    }
                } label: {
                    ZStack {
                        RemoteImage(
                            urlString: item.coverImageUrl ?? item.thumbnailUrl,
                            title: item.displayTitle,
                            systemFallback: "play.rectangle"
                        )
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Scrim + Play icon
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.black.opacity(0.25))
                        
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.white.opacity(0.92))
                            .shadow(color: .black.opacity(0.3), radius: 8)
                    }
                    .frame(height: 200)
                }
                .buttonStyle(.plain)
            }

            Text(item.displayTitle)
                .font(.headline)
            if let description = item.description, !description.isEmpty {
                Text(description.strippingHTML())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            HStack {
                TagFlow(tags: item.tags)
                Spacer()
                ExternalLinkButton(titleKey: "download", urlString: item.url, systemImage: "arrow.down.circle")
            }
        }
    }
}
