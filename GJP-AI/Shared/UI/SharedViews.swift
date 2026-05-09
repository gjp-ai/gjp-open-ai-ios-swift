import AVKit
import SwiftUI
import WebKit

struct FilterBar: View {
    @EnvironmentObject private var app: AppModel
    let tags: [String]
    @Binding var selectedTag: String?
    @Binding var sortOrder: SortOrder

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    tagButton(L10n.text("all", app.language), value: nil)
                        .id("tag_all")
                    ForEach(tags, id: \.self) { tag in
                        tagButton(tag, value: tag)
                            .id("tag_\(tag)")
                    }

                    Menu {
                        ForEach(SortOrder.allCases) { order in
                            Button {
                                sortOrder = order
                            } label: {
                                HStack {
                                    Text(L10n.text(order.rawValue, app.language))
                                    if sortOrder == order {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label(L10n.text("sort", app.language), systemImage: "line.3.horizontal.decrease")
                            .font(.subheadline.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .onChange(of: selectedTag) { _, newValue in
                withAnimation(.easeInOut(duration: 0.3)) {
                    let id = newValue.map { "tag_\($0)" } ?? "tag_all"
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
    }

    private func tagButton(_ title: String, value: String?) -> some View {
        let isSelected = selectedTag == value
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedTag = selectedTag == value ? nil : value
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected
                        ? AnyShapeStyle(app.tint.gradient)
                        : AnyShapeStyle(Color(.secondarySystemFill)),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

struct StateView<Content: View>: View {
    @EnvironmentObject private var app: AppModel
    let state: ScreenState<[any OpenListItem]>
    let retry: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        switch state {
        case .loading:
            ProgressView(L10n.text("loading", app.language))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            ContentUnavailableView(L10n.text("empty", app.language), systemImage: "tray")
        case let .error(message):
            ContentUnavailableView {
                Label(L10n.text("failed", app.language), systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button(L10n.text("retry", app.language), action: retry)
                    .buttonStyle(.borderedProminent)
            }
        case .content:
            content()
        }
    }
}

struct RemoteImage: View {
    let urlString: String?
    let title: String
    let systemFallback: String
    var contentMode: ContentMode = .fill

    private var parsedURL: URL? {
        guard let raw = urlString else { return nil }
        return ImageCache.parsedURL(from: raw)
    }

    var body: some View {
        if let url = parsedURL {
            Group {
                if url.pathExtension.lowercased() == "svg" {
                    SVGImage(url: url, contentMode: contentMode)
                } else {
                    CachedAsyncImage(url: url, contentMode: contentMode, systemFallback: systemFallback)
                        // KEY FIX: bind view identity to the URL so LazyVStack
                        // recycles don't keep a stale loading phase for the new URL.
                        .id(url)
                }
            }
            .accessibilityLabel(title)
        } else {
            fallbackView(systemFallback)
        }
    }
}

/// A cached image loader that bypasses `Cache-Control: no-store` server headers.
/// `AsyncImage` relies on `URLSession` which respects those headers and never
/// caches responses — causing blank images whenever a cell is reused or
/// the view re-renders. This view uses `ImageCache` (a custom two-level
/// memory + disk cache with `storagePolicy: .allowed`) to ensure images
/// are always served from cache after the first successful load.
private struct CachedAsyncImage: View {
    let url: URL
    let contentMode: ContentMode
    let systemFallback: String

    enum LoadPhase {
        case loading
        case success(UIImage)
        case failure
    }

    @State private var phase: LoadPhase = .loading
    @State private var loadedURL: URL? = nil

    var body: some View {
        content
            .task(id: url) {
                // Reset to loading only when the URL actually changes
                if loadedURL != url {
                    phase = .loading
                    loadedURL = url
                }
                await load(url)
            }
    }

    @ViewBuilder private var content: some View {
        switch phase {
        case .loading:
            ZStack {
                fallbackView(systemFallback).opacity(0.3)
                ProgressView().tint(.secondary)
            }
        case let .success(image):
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        case .failure:
            fallbackView(systemFallback)
        }
    }

    private func load(_ url: URL) async {
        do {
            let image = try await ImageCache.shared.image(for: url)
            withAnimation(.easeIn(duration: 0.2)) {
                phase = .success(image)
            }
        } catch {
            phase = .failure
        }
    }
}

private func fallbackView(_ systemName: String) -> some View {
    ZStack {
        Rectangle().fill(.quaternary)
            .frame(minHeight: 120)
        Image(systemName: systemName)
            .font(.title2)
            .foregroundStyle(.secondary)
    }
}

private struct SVGImage: View {
    let url: URL
    let contentMode: ContentMode
    
    var body: some View {
        SVGWebView(url: url, contentMode: contentMode)
            .clipped()
    }
}

private struct SVGWebView: UIViewRepresentable {
    let url: URL
    let contentMode: ContentMode

    final class Coordinator {
        var loadedURL: URL?
        var loadedContentMode: ContentMode?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.isUserInteractionEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Avoid reloading on every SwiftUI update pass — only reload when
        // the URL or content-mode actually changes, preventing SVG flicker.
        guard context.coordinator.loadedURL != url ||
              context.coordinator.loadedContentMode != contentMode else { return }
        context.coordinator.loadedURL = url
        context.coordinator.loadedContentMode = contentMode

        let objectFit = contentMode == .fill ? "cover" : "contain"
        let html = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body, html { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background: transparent; }
                img { width: 100%; height: 100%; object-fit: \(objectFit); }
            </style>
        </head>
        <body>
            <img src="\(url.absoluteString)">
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}

struct TagFlow: View {
    let tags: String?

    var body: some View {
        let list = tags?.tagList() ?? []
        if !list.isEmpty {
            HStack(spacing: 6) {
                ForEach(list.prefix(4), id: \.self) { tag in
                    Text(tag)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemFill), in: Capsule())
                        .lineLimit(1)
                }
            }
        }
    }
}

struct ExternalLinkButton: View {
    @EnvironmentObject private var app: AppModel
    let titleKey: String
    let urlString: String?
    let systemImage: String

    var body: some View {
        if let urlString, let url = URL(string: urlString) {
            Link(destination: url) {
                Label(L10n.text(titleKey, app.language), systemImage: systemImage)
                    .font(.subheadline.weight(.medium))
            }
        }
    }
}

struct OpenCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(.separator).opacity(0.25), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
            .shadow(color: .black.opacity(0.02), radius: 16, y: 8)
    }
}

extension View {
    func openListCardRow() -> some View {
        self
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
    }
}

struct LoadMoreButton: View {
    @EnvironmentObject private var app: AppModel
    let isLoading: Bool
    let action: () -> Void
    @State private var bouncing = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.down")
                        .font(.subheadline.weight(.bold))
                        .offset(y: bouncing ? 3 : 0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: bouncing)
                    Text(L10n.text("loadMore", app.language))
                        .font(.subheadline.weight(.semibold))
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(app.tint.gradient, in: Capsule())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .onAppear { bouncing = true }
    }
}

struct VideoPlayerView: View {
    let item: MediaItem

    var body: some View {
        if let urlString = item.url, let url = URL(string: urlString) {
            VideoPlayer(player: AVPlayer(url: url))
                .frame(minHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        } else {
            ContentUnavailableView(item.displayTitle, systemImage: "video.slash")
        }
    }
}

// MARK: - BackgroundRefreshBanner

/// Subtle pill shown when a ViewModel is silently refreshing cached data in background.
/// Appears at the top of a scroll view and auto-hides when refresh completes.
struct BackgroundRefreshBanner: View {
    var body: some View {
        HStack(spacing: 6) {
            ProgressView()
                .scaleEffect(0.75)
                .tint(.secondary)
            Text("Updating…")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(.bar, in: Capsule())
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        .padding(.top, 6)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
