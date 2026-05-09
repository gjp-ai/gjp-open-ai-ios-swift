import SwiftUI

struct ImageTile: View {
    let item: MediaItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(urlString: item.imageURL, title: item.altText ?? item.displayTitle, systemFallback: "photo")
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(item.displayTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.45))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
