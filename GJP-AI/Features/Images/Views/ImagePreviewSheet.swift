import SwiftUI

struct ImagePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var app: AppModel
    let items: [MediaItem]
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    init(item: MediaItem, items: [MediaItem]) {
        self.items = items
        self._currentIndex = State(initialValue: items.firstIndex(where: { $0.id == item.id }) ?? 0)
    }

    private var currentItem: MediaItem {
        items[currentIndex]
    }

    private var fullSizeUrl: String? {
        currentItem.imageURL
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $currentIndex) {
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]
                        
                        RemoteImage(urlString: item.imageURL, title: item.altText ?? item.displayTitle, systemFallback: "photo", contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .scaleEffect(currentIndex == index ? scale : 1.0)
                            .gesture(
                                currentIndex == index ? MagnifyGesture()
                                    .onChanged { value in
                                        scale = lastScale * value.magnification
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            scale = max(1.0, min(scale, 4.0))
                                            lastScale = scale
                                        }
                                    } : nil
                            )
                            .onTapGesture(count: 2) {
                                if currentIndex == index {
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
                            }
                            .clipped()
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                VStack(alignment: .leading, spacing: 10) {
                    Text(currentItem.displayTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    if let description = currentItem.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(3)
                    }
                    
                    HStack {
                        TagFlow(tags: currentItem.tags)
                        Spacer()
                        ExternalLinkButton(titleKey: "open", urlString: currentItem.originalUrl ?? currentItem.url, systemImage: "safari")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(white: 0.1))
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("\(currentIndex + 1) / \(items.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        withAnimation {
                            if currentIndex > 0 { currentIndex -= 1 }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(currentIndex == 0)

                    Button {
                        withAnimation {
                            if currentIndex < items.count - 1 { currentIndex += 1 }
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(currentIndex == items.count - 1)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("done", app.language)) { dismiss() }
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }
            .onChange(of: currentIndex) { _, _ in
                scale = 1.0
                lastScale = 1.0
            }
        }
        .preferredColorScheme(.dark)
    }
}
