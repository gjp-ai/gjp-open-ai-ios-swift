import SwiftUI

struct AnalyticsScreen: View {
    @EnvironmentObject private var app: AppModel
    @State private var state: ScreenState<[AnalyticsMetric]> = .loading

    private let api: OpenAPIClient

    init(api: OpenAPIClient = OpenAPIClient()) {
        self.api = api
    }

    var body: some View {
        ScrollView {
            Group {
                switch state {
                case .loading:
                    ProgressView(L10n.text("loading", app.language))
                        .frame(maxWidth: .infinity, minHeight: 320)
                case .empty:
                    ContentUnavailableView(L10n.text("empty", app.language), systemImage: "chart.bar")
                case let .error(message):
                    ContentUnavailableView {
                        Label(L10n.text("failed", app.language), systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button(L10n.text("retry", app.language)) {
                            Task { await load() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                case let .content(metrics):
                    AnalyticsContent(metrics: metrics)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaPadding(.bottom, 96)
        .navigationTitle(L10n.text("analytics", app.language))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: app.language) { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        state = .loading

        do {
            let language = app.language
            let loaded = try await [
                AnalyticsMetric(kind: .websites, total: api.websites(page: 0, size: 1, language: language, name: nil, tags: nil).totalElements),
                AnalyticsMetric(kind: .questions, total: api.questions(page: 0, size: 1, language: language, question: nil, tags: nil).totalElements),
                AnalyticsMetric(kind: .articles, total: api.articles(page: 0, size: 1, language: language, title: nil, tags: nil).totalElements),
                AnalyticsMetric(kind: .images, total: api.images(page: 0, size: 1, language: language, name: nil, tags: nil).totalElements),
                AnalyticsMetric(kind: .videos, total: api.videos(page: 0, size: 1, language: language, name: nil, tags: nil).totalElements),
                AnalyticsMetric(kind: .audios, total: api.audios(page: 0, size: 1, language: language, name: nil, tags: nil).totalElements),
                AnalyticsMetric(kind: .files, total: api.files(page: 0, size: 1, language: language, name: nil, tags: nil).totalElements)
            ]

            state = loaded.isEmpty ? .empty : .content(loaded)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
