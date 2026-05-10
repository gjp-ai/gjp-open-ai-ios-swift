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
                    CacheDataViewerScreen(title: L10n.text("settings", app.language), key: "appSettings", clearAction: clearAppSettings, dates: [settingsDate].compactMap { $0 })
                }
                databaseRow(title: L10n.text("websites", app.language), key: "websites")
                databaseRow(title: L10n.text("questions", app.language), key: "questions")
                databaseRow(title: L10n.text("articles", app.language), key: "articles")
                databaseRow(title: L10n.text("images", app.language), key: "images")
                databaseRow(title: L10n.text("videos", app.language), key: "videos")
                databaseRow(title: L10n.text("audios", app.language), key: "audios")
                databaseRow(title: L10n.text("files", app.language), key: "files")
            } header: {
                Text(L10n.text("dataCache", app.language))
            }

            Section {
                cacheRow(title: L10n.text("websiteLogos", app.language), size: Int64(cacheSizes["media_websites"] ?? 0), date: cacheDates["media_websites"] ?? nil, clearAction: { MediaCache.websites.clear(); loadSizes() }) {
                    MediaCacheViewerScreen(title: L10n.text("websiteLogos", app.language), cache: .websites)
                }
                cacheRow(title: L10n.text("articleCovers", app.language), size: Int64(cacheSizes["media_articles"] ?? 0), date: cacheDates["media_articles"] ?? nil, clearAction: { MediaCache.articles.clear(); loadSizes() }) {
                    MediaCacheViewerScreen(title: L10n.text("articleCovers", app.language), cache: .articles)
                }
                cacheRow(title: L10n.text("images", app.language), size: Int64(cacheSizes["media_media"] ?? 0), date: cacheDates["media_media"] ?? nil, clearAction: { MediaCache.media.clear(); loadSizes() }) {
                    MediaCacheViewerScreen(title: L10n.text("images", app.language), cache: .media)
                }
                cacheRow(title: L10n.text("videos", app.language), size: Int64(cacheSizes["media_videos"] ?? 0), date: cacheDates["media_videos"] ?? nil, clearAction: { MediaCache.videos.clear(); loadSizes() }) {
                    MediaCacheViewerScreen(title: L10n.text("videos", app.language), cache: .videos)
                }
                cacheRow(title: L10n.text("audios", app.language), size: Int64(cacheSizes["media_audios"] ?? 0), date: cacheDates["media_audios"] ?? nil, clearAction: { MediaCache.audios.clear(); loadSizes() }) {
                    MediaCacheViewerScreen(title: L10n.text("audios", app.language), cache: .audios)
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
        let keys = ["websites", "questions", "articles", "images", "videos", "audios", "files"]
        clearLegacyPayloadCaches(for: keys)
        databaseStats = SQLiteContentDatabase.shared.stats(for: keys)
        
        // Media buckets
        cacheSizes["media_websites"] = Int64(MediaCache.websites.diskSize)
        cacheSizes["media_articles"] = Int64(MediaCache.articles.diskSize)
        cacheSizes["media_media"] = Int64(MediaCache.media.diskSize)
        cacheSizes["media_videos"] = Int64(MediaCache.videos.diskSize)
        cacheSizes["media_audios"] = Int64(MediaCache.audios.diskSize)
        
        cacheDates["media_websites"] = MediaCache.websites.lastModified
        cacheDates["media_articles"] = MediaCache.articles.lastModified
        cacheDates["media_media"] = MediaCache.media.lastModified
        cacheDates["media_videos"] = MediaCache.videos.lastModified
        cacheDates["media_audios"] = MediaCache.audios.lastModified
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

    private func clearMediaCache() {
        MediaCache.websites.clear()
        MediaCache.articles.clear()
        MediaCache.media.clear()
        loadSizes()
    }
    
    private func clearAll() {
        CacheManager.clearAll()
        SQLiteContentDatabase.shared.clearAll()
        MediaCache.websites.clear()
        MediaCache.articles.clear()
        MediaCache.media.clear()
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
    @State private var rows: [SQLiteContentRow] = []
    @State private var selectedJsonItem: IdentifiableString?

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

                if rows.isEmpty {
                    if stats?.count ?? 0 > 0 {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ContentUnavailableView(L10n.text("empty", app.language), systemImage: "database")
                            .padding(.top, 40)
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 0) {
                            tableHeader
                            
                            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                                tableRow(index: index + 1, row: row)
                                Divider()
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
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
        .sheet(item: $selectedJsonItem) { item in
            JsonDetailsView(json: item.value)
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 8) {
            Text("NO.").frame(width: 30, alignment: .leading)
            Text("JSON").frame(width: 40, alignment: .center)
            Text("ID").frame(width: 80, alignment: .leading)
            Text("TITLE").frame(width: 150, alignment: .leading)
            Text("LANG").frame(width: 40, alignment: .leading)
            Text("TAGS").frame(width: 100, alignment: .leading)
            Text("ORDER").frame(width: 45, alignment: .leading)
            Text("UPDATED").frame(width: 85, alignment: .leading)
            Text("SYNCED").frame(width: 85, alignment: .leading)
            Text("SIZE").frame(width: 60, alignment: .trailing)
        }
        .font(.caption.bold())
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }

    private func tableRow(index: Int, row: SQLiteContentRow) -> some View {
        HStack(spacing: 8) {
            Text("\(index)")
                .frame(width: 30, alignment: .leading)
            
            Button {
                selectedJsonItem = IdentifiableString(value: row.json)
            } label: {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .frame(width: 40, alignment: .center)
            
            Text(row.id)
                .frame(width: 80, alignment: .leading)
            
            Text(row.title)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
            
            Text(row.lang)
                .frame(width: 40, alignment: .leading)

            Text(row.tags ?? "-")
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)

            Text("\(row.displayOrder)")
                .frame(width: 45, alignment: .leading)
            
            Text(String(row.updatedAt.prefix(16).replacingOccurrences(of: "T", with: " ")))
                .frame(width: 85, alignment: .leading)

            Text(formatDate(row.syncedAt))
                .frame(width: 85, alignment: .leading)

            Text(ByteCountFormatter.string(fromByteCount: row.size, countStyle: .file))
                .frame(width: 60, alignment: .trailing)
        }
        .font(.system(size: 9, design: .monospaced))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func formatDate(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }

    private func loadData() {
        DispatchQueue.global(qos: .userInitiated).async {
            let items = SQLiteContentDatabase.shared.rows(for: key)
            DispatchQueue.main.async {
                self.rows = items
            }
        }
    }
}

private struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}

private struct JsonDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    let json: String

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(prettyPrint(json))
                    .font(.system(.caption2, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("JSON Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func prettyPrint(_ string: String) -> String {
        guard let data = string.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
              let result = String(data: prettyData, encoding: .utf8) else {
            return string
        }
        return result
    }
}

private struct CacheDataViewerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var app: AppModel
    let title: String
    let key: String
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
            let content: String
            if key == "appSettings" {
                let settings = UserDefaults.standard.string(forKey: "gjp.appSettings.cache") ?? "No data found."
                content = prettyPrint(settings)
            } else {
                content = CacheManager.summary(for: key)
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
    let cache: MediaCache
    @State private var files: [MediaCache.CachedFile] = []

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
