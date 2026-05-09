import SafariServices
import SwiftUI

struct WebsiteBrowserScreen: View {
    @Environment(\.dismiss) private var dismiss
    let website: Website

    var body: some View {
        Group {
            if let url = website.normalizedURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            } else {
                NavigationStack {
                    ContentUnavailableView(
                        website.name,
                        systemImage: "link.badge.plus",
                        description: Text(APIError.invalidURL.localizedDescription)
                    )
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        configuration.barCollapsingEnabled = true

        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.dismissButtonStyle = .done
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
