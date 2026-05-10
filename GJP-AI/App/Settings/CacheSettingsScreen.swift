import SwiftUI

struct CacheSettingsScreen: View {
    @EnvironmentObject private var app: AppModel
    @State private var cacheSizes: [String: Int64] = [:]
    @State private var cacheDates: [String: Date?] = [:]
    @State private var databaseStats: [String: SQLiteContentStats] = [:]
    @State private var imageCacheSize: Int = 0

    private let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    var body: some View {
        List {
            Section {
                let settingsDate = userDefaultsDate()
                cacheRow(title: L10n.text("settings", app.language), size: userDefaultsSize(), date: settingsDate, clearAction: clearAppSettings) {
                    CacheDataViewerScreen(title: L10n.text("settings", app.language), clearAction: clearAppSettings, dates: [settingsDate].compactMap { $0 })
                }
                databaseRow(title: L10n.text("websites", app.language), key: "websites")
                databaseRow(title: L10n.text("questions", app.language), key: "questions")
                databaseRow(title: L10n.text("articles", app.language), key: "articles")
                databaseRow(title: L10n.text("images", app.language), key: "images")
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

    private func databaseRow(title: String, key: String) -> some View {
        let stats = databaseStats[key]
        let clearAction = {
            SQLiteContentDatabase.shared.clear(key: key)
            CacheManager.clear(forKey: "\(key)_EN")
            CacheManager.clear(forKey: "\(key)_ZH")
            loadSizes()
        }
        let rowTitle = "\(title) (\(stats?.count ?? 0))"

        return cacheRow(title: rowTitle, size: stats?.size ?? 0, date: stats?.lastModified ?? nil, clearAction: clearAction) {
            SQLiteDataViewerScreen(title: title, key: key, clearAction: clearAction, stats: stats)
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
        clearLegacyPayloadCaches(for: keys)
        databaseStats = SQLiteContentDatabase.shared.stats(for: keys)
        
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

    private func userDefaultsDate() -> Date? {
        let timestamp = UserDefaults.standard.double(forKey: "gjp.appSettings.cache.date")
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }

    private func clearAppSettings() {
        UserDefaults.standard.removeObject(forKey: "gjp.appSettings.cache")
        UserDefaults.standard.removeObject(forKey: "gjp.appSettings.cache.date")
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
        SQLiteContentDatabase.shared.clearAll()
        ImageCache.websites.clear()
        ImageCache.articles.clear()
        ImageCache.media.clear()
        UserDefaults.standard.removeObject(forKey: "gjp.appSettings.cache")
        loadSizes()
    }

    private func clearLegacyPayloadCaches(for keys: [String]) {
        for key in keys {
            CacheManager.clear(forKey: "\(key)_EN")
            CacheManager.clear(forKey: "\(key)_ZH")
            cacheSizes["\(key)_EN"] = 0
            cacheSizes["\(key)_ZH"] = 0
            cacheDates["\(key)_EN"] = nil
            cacheDates["\(key)_ZH"] = nil
        }
    }
}

private struct SQLiteDataViewerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var app: AppModel
    let title: String
    let key: String
    let clearAction: () -> Void
    let stats: SQLiteContentStats?
    @State private var rawData: String = ""

    private var lastUpdateString: String? {
        guard let latest = stats?.lastModified else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: latest)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.text("databaseRows", app.language, ["count": String(stats?.count ?? 0)]))
                    Text(L10n.text("databaseSize", app.language, [
                        "size": ByteCountFormatter.string(fromByteCount: stats?.size ?? 0, countStyle: .file)
                    ]))
                    if let updateString = lastUpdateString {
                        Text("\(L10n.text("lastUpdate", app.language)): \(updateString)")
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top, 8)

                if rawData.isEmpty {
                    ProgressView()
                        .padding()
                } else {
                    Text(rawData)
                        .font(.system(.caption2, design: .monospaced))
                        .padding()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
            let content = SQLiteContentDatabase.shared.rowSummary(for: key)
            DispatchQueue.main.async {
                self.rawData = content
            }
        }
    }
}

private struct CacheDataViewerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var app: AppModel
    let title: String
    let clearAction: () -> Void
    let dates: [Date]
    @State private var rawData: String = ""

    private var lastUpdateString: String? {
        guard let latest = dates.sorted().last else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: latest)
    }

    var body: some View {
        ScrollView {
            if rawData.isEmpty {
                ProgressView()
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    if let updateString = lastUpdateString {
                        Text("Last Update: \(updateString)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    
                    Text(rawData)
                        .font(.system(.caption2, design: .monospaced))
                        .padding()
                }
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
            let settings = UserDefaults.standard.string(forKey: "gjp.appSettings.cache") ?? "No data found."
            let content = prettyPrint(settings)
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
                    if let original = file.originalURL, let url = URL(string: original) {
                        Text(url.lastPathComponent)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                        Text(url.host ?? "")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text(file.id)
                            .font(.caption2.monospaced())
                            .lineLimit(1)
                    }
                    Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(file.date, style: .date)
                    Text(file.date, style: .time)
                }
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
