import SwiftUI

struct VideoCard: View {
    let item: MediaItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VideoPlayerView(item: item)
            Text(item.displayTitle)
                .font(.headline)
            if let description = item.description, !description.isEmpty {
                Text(description.strippingHTML())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack {
                TagFlow(tags: item.tags)
                Spacer()
                ExternalLinkButton(titleKey: "download", urlString: item.url, systemImage: "arrow.down.circle")
            }
        }
    }
}
