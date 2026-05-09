import SwiftUI

struct ArticleRow: View {
    let article: ArticleSummary

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RemoteImage(urlString: article.coverImageUrl, title: article.title, systemFallback: "newspaper")
                .frame(width: 96, height: 74)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator).opacity(0.2), lineWidth: 0.5)
                }
            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                if let summary = article.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: 6) {
                    if let source = article.sourceName, !source.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "building.2")
                                .font(.caption2)
                            Text(source)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    }
                    Spacer()
                    Text(article.updatedAt.prefix(10))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                TagFlow(tags: article.tags)
            }
        }
    }
}
