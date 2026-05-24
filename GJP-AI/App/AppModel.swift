import Combine
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    private let defaults: UserDefaults

    @Published var language: LanguageCode
    @Published var themeMode: ThemeMode
    @Published var accentChoice: AccentChoice
    @Published var settings: [AppSetting] = []
    @Published var settingsError: String?

    let api: OpenAPIClient

    init(api: OpenAPIClient? = nil, defaults: UserDefaults = .standard) {
        self.api = api ?? OpenAPIClient()
        self.defaults = defaults
        self.language = LanguageCode(rawValue: defaults.string(forKey: "gjp.language") ?? "") ?? .en
        self.themeMode = ThemeMode(rawValue: defaults.string(forKey: "gjp.theme") ?? "") ?? .system
        self.accentChoice = AccentChoice(rawValue: defaults.string(forKey: "gjp.accent") ?? "") ?? .blue
        loadCachedSettings()
    }

    var colorScheme: ColorScheme? {
        switch themeMode {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var totalCacheSize: Int64 {
        let dbSize = SQLiteContentDatabase.shared.totalFileSize
        let mediaSize = MediaCache.websites.diskSize +
                        MediaCache.articles.diskSize +
                        MediaCache.media.diskSize +
                        MediaCache.videos.diskSize +
                        MediaCache.audios.diskSize
        
        let cachedSettings = defaults.string(forKey: "gjp.appSettings.cache") ?? ""
        let settingsSize = Int64(cachedSettings.data(using: .utf8)?.count ?? 0)
        
        return dbSize + Int64(mediaSize) + settingsSize
    }

    var tint: Color {
        switch accentChoice {
        case .blue: .blue
        case .purple: .purple
        case .green: .green
        case .orange: .orange
        case .red: .red
        }
    }

    func setLanguage(_ value: LanguageCode) {
        language = value
        defaults.set(value.rawValue, forKey: "gjp.language")
    }

    func setThemeMode(_ value: ThemeMode) {
        themeMode = value
        defaults.set(value.rawValue, forKey: "gjp.theme")
    }

    func setAccentChoice(_ value: AccentChoice) {
        accentChoice = value
        defaults.set(value.rawValue, forKey: "gjp.accent")
    }

    func refreshSettings() async {
        do {
            let fetched = try await api.appSettings()
            settings = fetched
            settingsError = nil
            if let encoded = try? JSONEncoder().encode(fetched) {
                defaults.set(String(data: encoded, encoding: .utf8) ?? "", forKey: "gjp.appSettings.cache")
                defaults.set(Date().timeIntervalSince1970, forKey: "gjp.appSettings.cache.date")
            }
        } catch {
            // Only set error if we don't have any settings at all (neither fetched nor cached)
            if settings.isEmpty {
                settingsError = error.localizedDescription
            } else {
                // If we have cache, we don't treat the refresh failure as a fatal error for the splash
                settingsError = nil
            }
        }
    }

    func settingValue(_ name: String, language override: LanguageCode? = nil) -> String? {
        let lang = override ?? language
        return settings.first { $0.name == name && $0.lang == lang }?.value
    }

    func tags(_ name: String) -> [String] {
        settingValue(name)?
            .replacingOccurrences(of: "“", with: "")
            .replacingOccurrences(of: "”", with: "")
            .tagList() ?? []
    }

    private func loadCachedSettings() {
        let cachedSettings = defaults.string(forKey: "gjp.appSettings.cache") ?? ""
        guard let data = cachedSettings.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([AppSetting].self, from: data) else {
            return
        }
        settings = decoded
    }
}

enum L10n {
    static func text(_ key: String, _ language: LanguageCode, _ values: [String: String] = [:]) -> String {
        var result = translations[key]?[language] ?? translations[key]?[.en] ?? key
        for (key, value) in values {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return result
    }

    private static let translations: [String: [LanguageCode: String]] = [
        "websites": [.en: "Websites", .zh: "网站"],
        "questions": [.en: "Q&A", .zh: "问答"],
        "articles": [.en: "Articles", .zh: "文章"],
        "images": [.en: "Images", .zh: "图片"],
        "videos": [.en: "Videos", .zh: "视频"],
        "audios": [.en: "Audio", .zh: "音频"],
        "files": [.en: "Files", .zh: "文件"],
        "analytics": [.en: "Analytics", .zh: "数据分析"],
        "analyticsSubtitle": [.en: "Review public content coverage", .zh: "查看公开内容覆盖情况"],
        "analyticsHeadline": [.en: "Public content at a glance", .zh: "公开内容概览"],
        "analyticsSummary": [.en: "Counts are loaded from the public read-only API for the selected language.", .zh: "数据来自当前语言的公开只读 API。"],
        "totalItems": [.en: "Total items", .zh: "内容总数"],
        "contentMix": [.en: "Content mix", .zh: "内容分布"],
        "more": [.en: "More", .zh: "更多"],
        "library": [.en: "Library", .zh: "资源库"],
        "videosSubtitle": [.en: "Watch public video content", .zh: "观看公开视频内容"],
        "audiosSubtitle": [.en: "Listen to public audio content", .zh: "收听公开音频内容"],
        "filesSubtitle": [.en: "Open public downloadable files", .zh: "打开公开下载文件"],
        "search": [.en: "Search", .zh: "搜索"],
        "all": [.en: "All", .zh: "全部"],
        "sort": [.en: "Sort", .zh: "排序"],
        "displayOrder": [.en: "Default", .zh: "默认"],
        "alpha": [.en: "A-Z", .zh: "名称"],
        "recent": [.en: "Recent", .zh: "最近更新"],
        "loading": [.en: "Loading...", .zh: "正在加载..."],
        "empty": [.en: "Nothing to show yet.", .zh: "暂无内容。"],
        "failed": [.en: "Failed to load", .zh: "加载失败"],
        "retry": [.en: "Retry", .zh: "重试"],
        "open": [.en: "Open", .zh: "打开"],
        "download": [.en: "Download", .zh: "下载"],
        "saveToFiles": [.en: "Save to Files", .zh: "存储到文件"],
        "saveToPhotos": [.en: "Save to Photos", .zh: "保存到相册"],
        "fullScreen": [.en: "Full screen", .zh: "全屏"],
        "original": [.en: "Original", .zh: "原文"],
        "source": [.en: "Source", .zh: "来源"],
        "updated": [.en: "Updated", .zh: "更新"],
        "language": [.en: "Language", .zh: "语言"],
        "appearance": [.en: "Appearance", .zh: "外观"],
        "accent": [.en: "Accent", .zh: "主题色"],
        "settings": [.en: "Settings", .zh: "设置"],
        "player": [.en: "Player", .zh: "播放器"],
        "subtitles": [.en: "Subtitles", .zh: "字幕"],
        "system": [.en: "System", .zh: "跟随系统"],
        "light": [.en: "Light", .zh: "浅色"],
        "dark": [.en: "Dark", .zh: "深色"],
        "done": [.en: "Done", .zh: "完成"],
        "loadMore": [.en: "Load more", .zh: "加载更多"],
        "cache": [.en: "Cache", .zh: "缓存"],
        "dataCache": [.en: "Data Cache", .zh: "数据缓存"],
        "mediaCache": [.en: "Media Cache", .zh: "媒体缓存"],
        "clearAllCache": [.en: "Clear All Cache", .zh: "清空所有缓存"],
        "clear": [.en: "Clear", .zh: "清空"],
        "databaseRows": [.en: "{count} database rows", .zh: "{count} 条数据库记录"],
        "databaseSize": [.en: "Stored data: {size}", .zh: "已存数据：{size}"],
        "lastUpdate": [.en: "Last Update", .zh: "最后更新"],
        "websiteLogos": [.en: "Website Logos", .zh: "网站图标"],
        "articleCovers": [.en: "Article Cover Images", .zh: "文章封面"],
        "brandName": [.en: "GJP AI", .zh: "GJP AI"]
    ]
}
