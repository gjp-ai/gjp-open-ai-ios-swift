import SwiftUI

struct ImageTile: View {
    let item: MediaItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(urlString: item.imageURL, title: item.altText ?? item.displayTitle, systemFallback: "photo")
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            // Smooth gradient overlay for text readability
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.4),
                    .init(color: .black.opacity(0.6), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text(item.displayTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}
