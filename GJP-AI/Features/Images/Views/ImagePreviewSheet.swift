import SwiftUI

struct ImagePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var app: AppModel
    let item: MediaItem
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    RemoteImage(urlString: item.url ?? item.originalUrl ?? item.imageURL, title: item.altText ?? item.displayTitle, systemFallback: "photo")
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .scaleEffect(scale)
                        .gesture(
                            MagnifyGesture()
                                .onChanged { value in
                                    scale = lastScale * value.magnification
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        scale = max(1.0, min(scale, 4.0))
                                        lastScale = scale
                                    }
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                if scale > 1.0 {
                                    scale = 1.0
                                    lastScale = 1.0
                                } else {
                                    scale = 2.5
                                    lastScale = 2.5
                                }
                            }
                        }
                        .padding()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(item.displayTitle)
                            .font(.title3.weight(.semibold))
                        if let description = item.description, !description.isEmpty {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        TagFlow(tags: item.tags)
                        ExternalLinkButton(titleKey: "open", urlString: item.originalUrl ?? item.url, systemImage: "safari")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L10n.text("images", app.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("done", app.language)) { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
