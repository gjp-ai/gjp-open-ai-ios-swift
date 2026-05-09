import SwiftUI

struct WebsiteRow: View {
    let website: Website

    var body: some View {
        HStack(spacing: 14) {
            RemoteImage(urlString: website.logoUrl, title: website.name, systemFallback: "globe")
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.separator).opacity(0.2), lineWidth: 0.5)
                }
            VStack(alignment: .leading, spacing: 6) {
                Text(website.name)
                    .font(.headline)
                if let description = website.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                TagFlow(tags: website.tags)
            }
            Spacer()
            if let urlString = website.url, let url = URL(string: urlString) {
                Link(destination: url) {
                    Image(systemName: "arrow.up.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.accentColor.gradient, in: Circle())
                }
                .accessibilityLabel(website.name)
            }
        }
    }
}
