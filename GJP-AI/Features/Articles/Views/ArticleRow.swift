import SwiftUI

struct ArticleRow: View {
    let article: ArticleSummary

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RemoteImage(urlString: article.coverImageUrl, title: article.title, systemFallback: "newspaper")
                .frame(width: 92, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                if let summary = article.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                HStack {
                    TagFlow(tags: article.tags)
                    Spacer()
                    Text(article.updatedAt.prefix(10))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
