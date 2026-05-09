import SwiftUI

struct AnalyticsContent: View {
    @EnvironmentObject private var app: AppModel
    let metrics: [AnalyticsMetric]
    @State private var appeared = false

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
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("analyticsHeadline", app.language))
                    .font(.title2.weight(.bold))
                Text(L10n.text("analyticsSummary", app.language))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)

            // Total card
            OpenCard {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.text("totalItems", app.language))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        AnimatedCounter(value: appeared ? total : 0)
                    }
                    Spacer()
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(.tint)
                        .symbolRenderingMode(.hierarchical)
                        .rotationEffect(.degrees(appeared ? 0 : -90))
                }
            }
            .frame(height: 112)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            // Metric tiles grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 10)], spacing: 10) {
                ForEach(Array(metrics.enumerated()), id: \.element.id) { index, metric in
                    AnalyticsMetricTile(metric: metric, animated: appeared)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.06), value: appeared)
                }
            }

            // Bar chart card
            OpenCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text(L10n.text("contentMix", app.language))
                        .font(.headline)
                    ForEach(Array(topMetrics.enumerated()), id: \.element.id) { index, metric in
                        AnalyticsBarRow(metric: metric, maxValue: maxMetric, animated: appeared, delay: Double(index) * 0.08)
                    }
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Color.clear
                .frame(height: 72)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.75), value: appeared)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                appeared = true
            }
        }
    }
}

// MARK: - Animated Counter

struct AnimatedCounter: View {
    let value: Int

    var body: some View {
        Text(value.formatted())
            .font(.system(size: 44, weight: .bold, design: .rounded))
            .monospacedDigit()
            .contentTransition(.numericText(value: Double(value)))
            .animation(.spring(response: 0.8, dampingFraction: 0.7), value: value)
    }
}

// MARK: - Metric Tile

struct AnalyticsMetricTile: View {
    @EnvironmentObject private var app: AppModel
    let metric: AnalyticsMetric
    let animated: Bool

    var body: some View {
        OpenCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: metric.kind.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(metric.kind.tint)
                    .frame(width: 28, height: 28)
                    .background(metric.kind.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 4) {
                    Text((animated ? metric.total : 0).formatted())
                        .font(.subheadline.weight(.bold))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(animated ? metric.total : 0)))
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animated)
                    Text(metric.kind.title(language: app.language))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 90)
    }
}

// MARK: - Bar Row

struct AnalyticsBarRow: View {
    @EnvironmentObject private var app: AppModel
    let metric: AnalyticsMetric
    let maxValue: Int
    let animated: Bool
    let delay: Double

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
                        .frame(width: animated ? proxy.size.width * CGFloat(metric.total) / CGFloat(maxValue) : 0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.65).delay(delay + 0.3), value: animated)
                }
            }
            .frame(height: 10)
        }
    }
}
