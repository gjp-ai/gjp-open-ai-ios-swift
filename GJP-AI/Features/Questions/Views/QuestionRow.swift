import SwiftUI
import WebKit

struct QuestionRow: View {
    let question: Question
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    QuestionBadge()

                    Text(question.question)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .background(Color(.tertiarySystemGroupedBackground), in: Circle())
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(question.question)
            .accessibilityHint(isExpanded ? "Hide answer" : "Show answer")

            if isExpanded {
                QuestionAnswerHTMLView(html: question.answer)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        )
                    )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

private struct QuestionBadge: View {
    var body: some View {
        Text("Q")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
    }
}

private struct QuestionAnswerHTMLView: View {
    let html: String
    @State private var height: CGFloat = 80

    var body: some View {
        DynamicHTMLWebView(html: html, height: $height)
            .frame(height: height)
            .accessibilityLabel(html.strippingHTML())
    }
}

private struct DynamicHTMLWebView: UIViewRepresentable {
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
        let document = HTMLDocumentBuilder.document(for: html)
        if context.coordinator.loadedHTML != document {
            context.coordinator.loadedHTML = document
            webView.loadHTMLString(document, baseURL: nil)
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
                guard let value = result as? CGFloat else { return }
                let nextHeight = max(48, ceil(value))
                if abs(self.height - nextHeight) > 1 {
                    self.height = nextHeight
                }
            }
        }
    }
}

private enum HTMLDocumentBuilder {
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
                    color: #3c3c43;
                    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
                    font-size: 16px;
                    font-weight: 400;
                    line-height: 1.42;
                    overflow-wrap: anywhere;
                }
                @media (prefers-color-scheme: dark) {
                    html, body { color: #f2f2f7; }
                }
                p { margin: 0 0 10px; }
                p:last-child { margin-bottom: 0; }
                ul, ol { margin: 0 0 10px 20px; padding: 0; }
                li { margin: 0 0 6px; }
                img, video, iframe {
                    max-width: 100%;
                    height: auto;
                    border-radius: 10px;
                }
                a { color: -apple-system-link; text-decoration: none; }
                pre, code {
                    white-space: pre-wrap;
                    overflow-wrap: anywhere;
                    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
                }
            </style>
        </head>
        <body>\(body)</body>
        </html>
        """
    }
}
