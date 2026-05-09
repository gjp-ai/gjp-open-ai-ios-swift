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

private struct AnalyticsContent: View {
    @EnvironmentObject private var app: AppModel
    let metrics: [AnalyticsMetric]

    private var total: Int {
        metrics.reduce(0) { $0 + $1.total }
    }

    private var maxMetric: Int {
        max(metrics.map(\.total).max() ?? 1, 1)
    }

    private var topMetrics: [AnalyticsMetric] {
        metrics.sorted { $0.total > $1.total }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("analyticsHeadline", app.language))
                    .font(.title2.weight(.bold))
                Text(L10n.text("analyticsSummary", app.language))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            OpenCard {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.text("totalItems", app.language))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(total.formatted())
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                    Spacer()
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(.tint)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .frame(height: 112)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                ForEach(metrics) { metric in
                    AnalyticsMetricTile(metric: metric)
                }
            }

            OpenCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text(L10n.text("contentMix", app.language))
                        .font(.headline)
                    ForEach(topMetrics) { metric in
                        AnalyticsBarRow(metric: metric, maxValue: maxMetric)
                    }
                }
            }

            Color.clear
                .frame(height: 72)
        }
    }
}

private struct AnalyticsMetricTile: View {
    @EnvironmentObject private var app: AppModel
    let metric: AnalyticsMetric

    var body: some View {
        OpenCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: metric.kind.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(metric.kind.tint)
                    .frame(width: 26, height: 26)
                    .background(metric.kind.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.total.formatted())
                        .font(.subheadline.weight(.bold))
                        .monospacedDigit()
                    Text(metric.kind.title(language: app.language))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 86)
    }
}

private struct AnalyticsBarRow: View {
    @EnvironmentObject private var app: AppModel
    let metric: AnalyticsMetric
    let maxValue: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label(metric.kind.title(language: app.language), systemImage: metric.kind.systemImage)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(metric.total.formatted())
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                    Capsule()
                        .fill(metric.kind.tint.gradient)
                        .frame(width: proxy.size.width * CGFloat(metric.total) / CGFloat(maxValue))
                }
            }
            .frame(height: 9)
        }
    }
}

private struct AnalyticsMetric: Identifiable, Equatable {
    let kind: AnalyticsKind
    let total: Int

    var id: AnalyticsKind { kind }
}

private enum AnalyticsKind: CaseIterable {
    case websites
    case questions
    case articles
    case images
    case videos
    case audios
    case files

    var systemImage: String {
        switch self {
        case .websites: "globe"
        case .questions: "questionmark.circle.fill"
        case .articles: "newspaper.fill"
        case .images: "photo.on.rectangle.angled"
        case .videos: "play.rectangle.fill"
        case .audios: "music.note.list"
        case .files: "doc.richtext.fill"
        }
    }

    var tint: Color {
        switch self {
        case .websites: .blue
        case .questions: .indigo
        case .articles: .orange
        case .images: .green
        case .videos: .red
        case .audios: .purple
        case .files: .teal
        }
    }

    func title(language: LanguageCode) -> String {
        switch self {
        case .websites: L10n.text("websites", language)
        case .questions: L10n.text("questions", language)
        case .articles: L10n.text("articles", language)
        case .images: L10n.text("images", language)
        case .videos: L10n.text("videos", language)
        case .audios: L10n.text("audios", language)
        case .files: L10n.text("files", language)
        }
    }
}
