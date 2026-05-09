import SwiftUI

struct ArticleRow: View {
    let article: ArticleSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if article.coverImageUrl != nil {
                RemoteImage(urlString: article.coverImageUrl, title: article.title, systemFallback: "newspaper")
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(.separator).opacity(0.18), lineWidth: 0.5)
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                ArticleMetaLine(source: article.sourceName, updatedAt: article.updatedAt)

                Text(article.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let summary = article.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .lineSpacing(2)
                }

                TagFlow(tags: article.tags)
            }
        }
    }
}

private struct ArticleMetaLine: View {
    let source: String?
    let updatedAt: String

    var body: some View {
        HStack(spacing: 8) {
            if let source, !source.isEmpty {
                Label(source, systemImage: "building.2")
                    .lineLimit(1)
            }

            if source?.isEmpty == false {
                Circle()
                    .fill(Color.secondary.opacity(0.35))
                    .frame(width: 4, height: 4)
            }

            Label(String(updatedAt.prefix(10)), systemImage: "calendar")
                .lineLimit(1)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
        .labelStyle(.titleAndIcon)
    }
}
