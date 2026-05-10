import SwiftUI
import WebKit

struct ArticleDetailScreen: View {
    @EnvironmentObject private var app: AppModel
    let article: ArticleSummary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let coverUrl = article.coverImageUrl, !coverUrl.isEmpty {
                    RemoteImage(urlString: coverUrl, title: article.title, systemFallback: "newspaper", contentMode: .fit, cache: .articles)
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .bottomLeading) {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.25),
                                    .init(color: Color.black.opacity(0.45), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                }

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        if let source = article.sourceName, !source.isEmpty {
                            Label(source, systemImage: "building.2")
                                .lineLimit(1)
                        }

                        if article.sourceName?.isEmpty == false {
                            Circle()
                                .fill(Color.secondary.opacity(0.35))
                                .frame(width: 4, height: 4)
                        }

                        Label(String(article.updatedAt.prefix(10)), systemImage: "calendar")
                            .lineLimit(1)
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)

                    Text(article.title)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 12) {
                        ExternalLinkButton(titleKey: "original", urlString: article.originalUrl, systemImage: "safari")
                        Spacer()
                    }

                    Divider()

                    if let content = article.content, !content.isEmpty {
                        ArticleHTMLContentView(html: content)
                    } else {
                        ContentUnavailableView(L10n.text("empty", app.language), systemImage: "doc.text")
                    }

                    TagFlow(tags: article.tags)
                }
                .padding(.horizontal, 18)
                .padding(.top, article.coverImageUrl == nil ? 18 : 20)
                .padding(.bottom, 28)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Prefetch images found in HTML to help with offline view
            prefetchImages(from: article.content ?? "")
        }
    }

    private func prefetchImages(from html: String) {
        // Simple regex to find image URLs in HTML
        let pattern = "<img [^>]*src=\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return }
        
        let nsString = html as NSString
        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
        
        let urls = matches.compactMap { match -> String? in
            guard match.numberOfRanges > 1 else { return nil }
            return nsString.substring(with: match.range(at: 1))
        }
        
        if !urls.isEmpty {
            ImageCache.articles.prefetch(urlStrings: urls)
        }
    }
}

private struct ArticleHTMLContentView: View {
    let html: String
    @State private var height: CGFloat = 120

    var body: some View {
        ArticleHTMLWebView(html: html, height: $height)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(html.strippingHTML())
    }
}

private struct ArticleHTMLWebView: UIViewRepresentable {
    let html: String
    @Binding var height: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(height: $height)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.backgroundColor = .clear
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let document = ArticleHTMLDocument.document(for: html)
        if context.coordinator.loadedHTML != document {
            context.coordinator.loadedHTML = document
            webView.loadHTMLString(document, baseURL: Bundle.main.bundleURL)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding private var height: CGFloat
        var loadedHTML: String?

        init(height: Binding<CGFloat>) {
            _height = height
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            updateHeight(webView)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.updateHeight(webView)
            }
        }

        private func updateHeight(_ webView: WKWebView) {
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { result, _ in
                let measured: CGFloat?
                if let number = result as? NSNumber {
                    measured = CGFloat(truncating: number)
                } else {
                    measured = result as? CGFloat
                }

                guard let measured else { return }
                let nextHeight = max(80, ceil(measured))
                if abs(self.height - nextHeight) > 1 {
                    self.height = nextHeight
                }
            }
        }
    }
}

private enum ArticleHTMLDocument {
    static func document(for body: String) -> String {
        """
        <!doctype html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
            <style>
                :root { color-scheme: light dark; }
                html, body {
                    margin: 0;
                    padding: 0;
                    background: transparent;
                    color: #1c1c1e;
                    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
                    font-size: 17px;
                    line-height: 1.55;
                    overflow-wrap: anywhere;
                }
                @media (prefers-color-scheme: dark) {
                    html, body { color: #f2f2f7; }
                }
                h1, h2, h3 {
                    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
                    line-height: 1.18;
                    margin: 24px 0 10px;
                }
                h1:first-child, h2:first-child, h3:first-child { margin-top: 0; }
                p { margin: 0 0 14px; }
                p:last-child { margin-bottom: 0; }
                ul, ol { margin: 0 0 14px 22px; padding: 0; }
                li { margin: 0 0 8px; }
                img, video, iframe {
                    display: block;
                    max-width: 100%;
                    height: auto;
                    margin: 16px 0;
                    border-radius: 12px;
                }
                blockquote {
                    margin: 18px 0;
                    padding: 12px 14px;
                    border-left: 3px solid #af52de;
                    background: rgba(175, 82, 222, 0.08);
                    border-radius: 10px;
                }
                a { color: -apple-system-link; text-decoration: none; }
                pre, code {
                    white-space: pre-wrap;
                    overflow-wrap: anywhere;
                    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
                    font-size: 0.92em;
                }
                pre {
                    padding: 12px;
                    border-radius: 12px;
                    background: rgba(120, 120, 128, 0.14);
                }
            </style>
        </head>
        <body>\(body)</body>
        </html>
        """
    }
}
