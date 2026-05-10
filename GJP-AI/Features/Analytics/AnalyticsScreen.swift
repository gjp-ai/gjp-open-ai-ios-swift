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
            let loaded = [
                AnalyticsMetric(kind: .websites, total: SQLiteContentDatabase.shared.count(key: "websites", language: language)),
                AnalyticsMetric(kind: .questions, total: SQLiteContentDatabase.shared.count(key: "questions", language: language)),
                AnalyticsMetric(kind: .articles, total: SQLiteContentDatabase.shared.count(key: "articles", language: language)),
                AnalyticsMetric(kind: .images, total: SQLiteContentDatabase.shared.count(key: "images", language: language)),
                AnalyticsMetric(kind: .videos, total: SQLiteContentDatabase.shared.count(key: "videos", language: language)),
                AnalyticsMetric(kind: .audios, total: SQLiteContentDatabase.shared.count(key: "audios", language: language)),
                AnalyticsMetric(kind: .files, total: SQLiteContentDatabase.shared.count(key: "files", language: language))
            ]

            state = loaded.isEmpty ? .empty : .content(loaded)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
