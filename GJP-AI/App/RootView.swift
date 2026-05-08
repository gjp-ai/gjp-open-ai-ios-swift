import SwiftUI

struct RootView: View {
    @StateObject private var app = AppModel()

    var body: some View {
        TabView {
            WebsitesScreen()
                .tabItem { Label(L10n.text("websites", app.language), systemImage: "globe") }
            QuestionsScreen()
                .tabItem { Label(L10n.text("questions", app.language), systemImage: "questionmark.circle") }
            ArticlesScreen()
                .tabItem { Label(L10n.text("articles", app.language), systemImage: "newspaper") }
            ImagesScreen()
                .tabItem { Label(L10n.text("images", app.language), systemImage: "photo.on.rectangle") }
            VideosScreen()
                .tabItem { Label(L10n.text("videos", app.language), systemImage: "play.rectangle") }
            AudiosScreen()
                .tabItem { Label(L10n.text("audios", app.language), systemImage: "music.note") }
            FilesScreen()
                .tabItem { Label(L10n.text("files", app.language), systemImage: "doc") }
        }
        .environmentObject(app)
        .tint(app.tint)
        .preferredColorScheme(app.colorScheme)
        .task {
            await app.refreshSettings()
        }
    }
}

struct SettingsMenu: ToolbarContent {
    @EnvironmentObject private var app: AppModel

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker(L10n.text("language", app.language), selection: Binding(
                    get: { app.language },
                    set: { app.setLanguage($0) }
                )) {
                    Text("English").tag(LanguageCode.en)
                    Text("中文").tag(LanguageCode.zh)
                }

                Picker(L10n.text("appearance", app.language), selection: Binding(
                    get: { app.themeMode },
                    set: { app.setThemeMode($0) }
                )) {
                    Text(L10n.text("system", app.language)).tag(ThemeMode.system)
                    Text(L10n.text("light", app.language)).tag(ThemeMode.light)
                    Text(L10n.text("dark", app.language)).tag(ThemeMode.dark)
                }

                Picker(L10n.text("accent", app.language), selection: Binding(
                    get: { app.accentChoice },
                    set: { app.setAccentChoice($0) }
                )) {
                    ForEach(AccentChoice.allCases) { accent in
                        Text(accent.rawValue.capitalized).tag(accent)
                    }
                }
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel(L10n.text("settings", app.language))
        }
    }
}

#Preview {
    RootView()
}
