import SwiftUI

struct AudioRow: View {
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
