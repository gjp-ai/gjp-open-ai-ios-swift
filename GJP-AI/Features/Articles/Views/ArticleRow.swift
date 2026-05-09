import SwiftUI

struct ArticleRow: View {
    let article: ArticleSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let coverUrl = article.coverImageUrl, !coverUrl.isEmpty {
                RemoteImage(urlString: coverUrl, title: article.title, systemFallback: "newspaper", contentMode: .fit, cache: .articles)
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .clipped()
            }

            VStack(alignment: .leading, spacing: 12) {
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

                HStack(alignment: .center, spacing: 8) {
                    TagFlow(tags: article.tags)
                    
                    if let source = article.sourceName, !source.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary.opacity(0.5))
                        Text(source)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Text(String(article.updatedAt.prefix(10)))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .trailing)
                }
            }
            .padding(16)
        }
        .background(Color(.secondarySystemGroupedBackground))
    }
}


