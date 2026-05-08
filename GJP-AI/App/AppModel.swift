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
            }
        } catch {
            settingsError = error.localizedDescription
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
        "loadMore": [.en: "Load more", .zh: "加载更多"]
    ]
}
