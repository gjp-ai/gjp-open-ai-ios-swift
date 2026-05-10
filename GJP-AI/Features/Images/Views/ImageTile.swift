import SwiftUI

struct ImageTile: View {
    let item: MediaItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RemoteImage(urlString: item.imageURL, title: item.altText ?? item.displayTitle, systemFallback: "photo", contentMode: .fit, cache: .media)
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
