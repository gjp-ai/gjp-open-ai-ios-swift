import SwiftUI

struct CacheSettingsScreen: View {
    @EnvironmentObject private var app: AppModel
    @State private var cacheSizes: [String: Int64] = [:]
    @State private var cacheDates: [String: Date?] = [:]
    @State private var imageCacheSize: Int = 0

    private let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    var body: some View {
        List {
            Section {
                cacheRow(title: L10n.text("settings", app.language), size: userDefaultsSize(), date: nil, clearAction: clearAppSettings) {
                    CacheDataViewerScreen(title: L10n.text("settings", app.language), key: nil, clearAction: clearAppSettings)
                }
                cacheRow(title: L10n.text("websites", app.language), key: "websites")
                cacheRow(title: L10n.text("questions", app.language), key: "questions")
                cacheRow(title: L10n.text("articles", app.language), key: "articles")
                cacheRow(title: L10n.text("images", app.language), key: "images")
            } header: {
                Text(L10n.text("dataCache", app.language))
            }

            Section {
                cacheRow(title: L10n.text("websiteLogos", app.language), size: Int64(cacheSizes["media_websites"] ?? 0), date: cacheDates["media_websites"] ?? nil, clearAction: { ImageCache.websites.clear(); loadSizes() }) {
                    MediaCacheViewerScreen(title: L10n.text("websiteLogos", app.language), cache: .websites)
                }
                cacheRow(title: L10n.text("articleCovers", app.language), size: Int64(cacheSizes["media_articles"] ?? 0), date: cacheDates["media_articles"] ?? nil, clearAction: { ImageCache.articles.clear(); loadSizes() }) {
                    MediaCacheViewerScreen(title: L10n.text("articleCovers", app.language), cache: .articles)
                }
                cacheRow(title: L10n.text("images", app.language), size: Int64(cacheSizes["media_media"] ?? 0), date: cacheDates["media_media"] ?? nil, clearAction: { ImageCache.media.clear(); loadSizes() }) {
                    MediaCacheViewerScreen(title: L10n.text("images", app.language), cache: .media)
                }
            } header: {
                Text(L10n.text("mediaCache", app.language))
            }
            
            Section {
                Button(role: .destructive) {
                    clearAll()
                } label: {
                    Text(L10n.text("clearAllCache", app.language))
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle(L10n.text("cache", app.language))
        .onAppear(perform: loadSizes)
    }

    private func cacheRow(title: String, key: String) -> some View {
        let size = (cacheSizes["\(key)_EN"] ?? 0) + (cacheSizes["\(key)_ZH"] ?? 0)
        let date = [cacheDates["\(key)_EN"] ?? nil, cacheDates["\(key)_ZH"] ?? nil].compactMap { $0 }.sorted().last
        
        let clearAction = {
            CacheManager.clear(forKey: "\(key)_EN")
            CacheManager.clear(forKey: "\(key)_ZH")
            loadSizes()
        }
        
        return cacheRow(title: title, size: size, date: date, clearAction: clearAction) {
            CacheDataViewerScreen(title: title, key: key, clearAction: clearAction)
        }
    }

    private func cacheRow(title: String, size: Int64, date: Date?, clearAction: @escaping () -> Void) -> some View {
        cacheRowContent(title: title, size: size, date: date, clearAction: clearAction, destination: nil)
    }

    private func cacheRow<Destination: View>(title: String, size: Int64, date: Date?, clearAction: @escaping () -> Void, @ViewBuilder destination: () -> Destination) -> some View {
        cacheRowContent(title: title, size: size, date: date, clearAction: clearAction, destination: AnyView(destination()))
    }

    private func cacheRowContent(title: String, size: Int64, date: Date?, clearAction: @escaping () -> Void, destination: AnyView?) -> some View {
        Group {
            if let destination {
                NavigationLink(destination: destination) {
                    rowBody(title: title, size: size, date: date)
                }
            } else {
                rowBody(title: title, size: size, date: date)
            }
        }
        .padding(.vertical, 4)
    }

    private func rowBody(title: String, size: Int64, date: Date?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.body)
            HStack(spacing: 8) {
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                if let date = date {
                    Text("•")
                    Text(dateFormatter.localizedString(for: date, relativeTo: Date()))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func loadSizes() {
        let keys = ["websites", "questions", "articles", "images"]
        for key in keys {
            cacheSizes["\(key)_EN"] = CacheManager.size(forKey: "\(key)_EN")
            cacheSizes["\(key)_ZH"] = CacheManager.size(forKey: "\(key)_ZH")
            cacheDates["\(key)_EN"] = CacheManager.lastModified(forKey: "\(key)_EN")
            cacheDates["\(key)_ZH"] = CacheManager.lastModified(forKey: "\(key)_ZH")
        }
        
        // Media buckets
        cacheSizes["media_websites"] = Int64(ImageCache.websites.diskSize)
        cacheSizes["media_articles"] = Int64(ImageCache.articles.diskSize)
        cacheSizes["media_media"] = Int64(ImageCache.media.diskSize)
        
        cacheDates["media_websites"] = ImageCache.websites.lastModified
        cacheDates["media_articles"] = ImageCache.articles.lastModified
        cacheDates["media_media"] = ImageCache.media.lastModified
    }

    private func userDefaultsSize() -> Int64 {
        let cachedSettings = UserDefaults.standard.string(forKey: "gjp.appSettings.cache") ?? ""
        return Int64(cachedSettings.data(using: .utf8)?.count ?? 0)
    }

    private func clearAppSettings() {
        UserDefaults.standard.removeObject(forKey: "gjp.appSettings.cache")
        loadSizes()
    }

    private func clearImageCache() {
        ImageCache.websites.clear()
        ImageCache.articles.clear()
        ImageCache.media.clear()
        loadSizes()
    }
    
    private func clearAll() {
        CacheManager.clearAll()
        ImageCache.websites.clear()
        ImageCache.articles.clear()
        ImageCache.media.clear()
        UserDefaults.standard.removeObject(forKey: "gjp.appSettings.cache")
        loadSizes()
    }
}

private struct CacheDataViewerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var app: AppModel
    let title: String
    let key: String?
    let clearAction: () -> Void
    @State private var rawData: String = ""

    var body: some View {
        ScrollView {
            if rawData.isEmpty {
                ProgressView()
                    .padding()
            } else {
                Text(rawData)
                    .font(.system(.caption2, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle(title)
        .onAppear(perform: loadData)
        .background(Color(.systemBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    clearAction()
                    dismiss()
                } label: {
                    Text(L10n.text("clear", app.language))
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func loadData() {
        DispatchQueue.global(qos: .userInitiated).async {
            let content: String
            if let key = key {
                var text = ""
                if let en = CacheManager.loadRaw(forKey: "\(key)_EN") {
                    text += "--- EN ---\n\(prettyPrint(en))\n\n"
                }
                if let zh = CacheManager.loadRaw(forKey: "\(key)_ZH") {
                    text += "--- ZH ---\n\(prettyPrint(zh))\n"
                }
                content = text.isEmpty ? "No data found." : text
            } else {
                let settings = UserDefaults.standard.string(forKey: "gjp.appSettings.cache") ?? "No data found."
                content = prettyPrint(settings)
            }
            
            DispatchQueue.main.async {
                self.rawData = content
            }
        }
    }

    private func prettyPrint(_ string: String) -> String {
        guard let data = string.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let result = String(data: prettyData, encoding: .utf8) else {
            return string
        }
        return result
    }
}

private struct MediaCacheViewerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var app: AppModel
    let title: String
    let cache: ImageCache
    @State private var files: [ImageCache.CachedFile] = []

    var body: some View {
        List(files) { file in
            HStack(spacing: 12) {
                if let image = UIImage(contentsOfFile: file.url.path) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "photo")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .background(Color(.quaternarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.id)
                        .font(.caption2.monospaced())
                        .lineLimit(1)
                    Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(file.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 2)
        }
        .navigationTitle(title)
        .onAppear { files = cache.allCachedFiles() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    cache.clear()
                    dismiss()
                } label: {
                    Text(L10n.text("clear", app.language))
                        .foregroundStyle(.red)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CacheSettingsScreen()
            .environmentObject(AppModel())
    }
}
