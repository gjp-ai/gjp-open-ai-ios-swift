import SwiftUI

struct WebsiteRow: View {
    let website: Website

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 10) {
                RemoteImage(urlString: website.logoUrl, title: website.name, systemFallback: "globe")
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color(.separator).opacity(0.18), lineWidth: 0.5)
                    }
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)

                Text(website.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .allowsTightening(true)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let description = website.description?.trimmingCharacters(in: .whitespacesAndNewlines), !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.18), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(website.name)
    }
}

extension Website {
    var normalizedURL: URL? {
        guard let trimmed = url?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }

        if let parsed = URL(string: trimmed), parsed.scheme != nil {
            return parsed
        }

        return URL(string: "https://\(trimmed)")
    }

}
