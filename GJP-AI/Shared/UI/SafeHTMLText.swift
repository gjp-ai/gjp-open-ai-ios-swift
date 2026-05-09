import SwiftUI

struct SafeHTMLText: View {
    let html: String
    @State private var attributedString: AttributedString?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let attributedString {
                Text(attributedString)
            } else {
                Text(html.strippingHTML())
                    .foregroundStyle(.secondary)
                    .italic()
                    .onAppear {
                        load()
                    }
            }
        }
    }

    private func load() {
        guard attributedString == nil, !isLoading else { return }
        isLoading = true
        
        // We must use the main thread for NSAttributedString HTML conversion,
        // but we can wrap it in an async task to avoid blocking the immediate UI render.
        DispatchQueue.main.async {
            let result = HTMLConverter.shared.convert(html)
            self.attributedString = result
            self.isLoading = false
        }
    }
}

/// Singleton to manage HTML conversion and caching
private class HTMLConverter {
    static let shared = HTMLConverter()
    private var cache: [String: AttributedString] = [:]
    private let lock = NSLock()

    func convert(_ html: String) -> AttributedString {
        lock.lock()
        if let cached = cache[html] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let converted: AttributedString
        if let data = html.data(using: .utf8),
           let ns = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
           ),
           let swiftUI = try? AttributedString(ns, including: \.uiKit) {
            converted = swiftUI
        } else {
            converted = AttributedString(html.strippingHTML())
        }

        lock.lock()
        cache[html] = converted
        lock.unlock()
        return converted
    }
}
