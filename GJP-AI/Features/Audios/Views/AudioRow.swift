import SwiftUI

struct AudioRow: View {
    let item: MediaItem
    let isActive: Bool

    var body: some View {
        HStack(spacing: 14) {
            RemoteImage(urlString: item.coverImageUrl, title: item.displayTitle, systemFallback: "music.note")
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay {
                    if isActive {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.tint, lineWidth: 2)
                    }
                }
            VStack(alignment: .leading, spacing: 5) {
                Text(item.displayTitle)
                    .font(.headline)
                    .foregroundStyle(isActive ? Color.accentColor : Color.primary)
                if let artist = item.artist, !artist.isEmpty {
                    Text(artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                TagFlow(tags: item.tags)
            }
            Spacer()
            Image(systemName: isActive ? "pause.circle.fill" : "play.circle.fill")
                .font(.title)
                .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
                .symbolEffect(.pulse, isActive: isActive)
        }
        .padding(.vertical, isActive ? 2 : 0)
        .animation(.easeInOut(duration: 0.25), value: isActive)
    }
}
