import SwiftUI

struct ImagePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var app: AppModel
    let item: MediaItem

    var body: some View {
        NavigationStack {
            ScrollView {
                RemoteImage(urlString: item.url ?? item.originalUrl ?? item.imageURL, title: item.altText ?? item.displayTitle, systemFallback: "photo")
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding()
                VStack(alignment: .leading, spacing: 10) {
                    Text(item.displayTitle)
                        .font(.title3.weight(.semibold))
                    TagFlow(tags: item.tags)
                    ExternalLinkButton(titleKey: "open", urlString: item.originalUrl ?? item.url, systemImage: "safari")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle(L10n.text("images", app.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("done", app.language)) { dismiss() }
                }
            }
        }
    }
}
