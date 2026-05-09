import SwiftUI

struct ArticleDetailScreen: View {
    @EnvironmentObject private var app: AppModel
    let articleID: String
    let api: OpenAPIClient
    @State private var state: ScreenState<ArticleDetail> = .loading
    @State private var showCover = true

    var body: some View {
        ScrollView {
            switch state {
            case .loading:
                ProgressView(L10n.text("loading", app.language))
                    .padding()
            case let .error(message):
                ContentUnavailableView(L10n.text("failed", app.language), systemImage: "exclamationmark.triangle", description: Text(message))
            case .empty:
                ContentUnavailableView(L10n.text("empty", app.language), systemImage: "newspaper")
            case let .content(article):
                VStack(alignment: .leading, spacing: 18) {
                    if showCover, article.coverImageUrl != nil {
                        RemoteImage(urlString: article.coverImageUrl, title: article.title, systemFallback: "newspaper")
                            .frame(maxWidth: .infinity)
                            .frame(height: 230)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    SafeHTMLText(html: article.content)
                        .textSelection(.enabled)
                    HStack {
                        ExternalLinkButton(titleKey: "original", urlString: article.originalUrl, systemImage: "safari")
                        Spacer()
                        if article.coverImageUrl != nil {
                            Button {
                                showCover.toggle()
                            } label: {
                                Image(systemName: showCover ? "photo" : "photo.slash")
                            }
                        }
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        if let source = article.sourceName, !source.isEmpty {
                            Label(source, systemImage: "building.2")
                        }
                        if let tags = article.tags, !tags.isEmpty {
                            Label(tags, systemImage: "tag")
                        }
                        Label(String(article.updatedAt.prefix(10)), systemImage: "calendar")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: articleID) { await load() }
    }

    private func load() async {
        state = .loading
        do {
            state = .content(try await api.article(id: articleID))
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
