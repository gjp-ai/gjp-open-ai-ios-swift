import SwiftUI

struct WebsiteRow: View {
    let website: Website

    var body: some View {
        HStack(spacing: 14) {
            RemoteImage(urlString: website.logoUrl, title: website.name, systemFallback: "globe")
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    Image(systemName: "arrow.up.right.square")
                        .font(.title3)
                }
                .accessibilityLabel(website.name)
            }
        }
    }
}
