import SwiftUI

struct ImageTile: View {
    let item: MediaItem

    private var displayUrl: String? {
        [item.url, item.originalUrl, item.coverImageUrl, item.thumbnailUrl]
            .compactMap { $0 }
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RemoteImage(urlString: displayUrl, title: item.altText ?? item.displayTitle, systemFallback: "photo", contentMode: .fit, cache: .media)
                .frame(maxWidth: .infinity, minHeight: 200)
                .clipped()

            Text(item.displayTitle)
                .font(.headline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 12)
        .background(Color(.secondarySystemGroupedBackground))
    }
}
