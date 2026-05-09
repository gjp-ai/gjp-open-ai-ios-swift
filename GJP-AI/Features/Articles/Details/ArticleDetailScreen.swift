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
                    .frame(maxWidth: .infinity, minHeight: 300)
            case let .error(message):
                ContentUnavailableView(L10n.text("failed", app.language), systemImage: "exclamationmark.triangle", description: Text(message))
                    .frame(minHeight: 300)
            case .empty:
                ContentUnavailableView(L10n.text("empty", app.language), systemImage: "newspaper")
                    .frame(minHeight: 300)
            case let .content(article):
                VStack(alignment: .leading, spacing: 0) {
                    // Hero cover image
                    if showCover, article.coverImageUrl != nil {
                        RemoteImage(urlString: article.coverImageUrl, title: article.title, systemFallback: "newspaper")
                            .frame(maxWidth: .infinity)
                            .frame(height: 240)
                            .clipped()
                            .overlay(alignment: .bottomLeading) {
                                // Gradient scrim for title readability over image
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0.3),
                                        .init(color: Color(.systemBackground).opacity(0.85), location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        // Title
                        Text(article.title)
                            .font(.title2.weight(.bold))
                            .fixedSize(horizontal: false, vertical: true)

                        // Content
                        SafeHTMLText(html: article.content)
                            .textSelection(.enabled)

                        // Actions
                        HStack {
                            ExternalLinkButton(titleKey: "original", urlString: article.originalUrl, systemImage: "safari")
                            Spacer()
                            if article.coverImageUrl != nil {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showCover.toggle()
                                    }
                                } label: {
                                    Image(systemName: showCover ? "photo.fill" : "photo.slash")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        Divider()

                        // Metadata
                        VStack(alignment: .leading, spacing: 10) {
                            if let source = article.sourceName, !source.isEmpty {
                                Label {
                                    Text(source)
                                } icon: {
                                    Image(systemName: "building.2")
                                        .foregroundStyle(.tint)
                                }
                            }
                            if let tags = article.tags, !tags.isEmpty {
                                TagFlow(tags: tags)
                            }
                            Label {
                                Text(String(article.updatedAt.prefix(10)))
                            } icon: {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                }
            }
        }
        .background(Color(.systemBackground))
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
