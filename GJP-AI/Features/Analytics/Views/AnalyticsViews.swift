import SwiftUI

struct AnalyticsContent: View {
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

struct AnalyticsMetricTile: View {
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

struct AnalyticsBarRow: View {
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
