import SwiftUI

struct RootView: View {
    @StateObject private var app = AppModel()
    @State private var showingSplash = true

    var body: some View {
        ZStack {
            if showingSplash {
                SplashScreen(app: app) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showingSplash = false
                    }
                }
                .environmentObject(app)
                .transition(.opacity)
            } else {
                TabView {
                    WebsitesScreen()
                        .tabItem { Label(L10n.text("websites", app.language), systemImage: "globe") }
                    QuestionsScreen()
                        .tabItem { Label(L10n.text("questions", app.language), systemImage: "questionmark.circle") }
                    ArticlesScreen()
                        .tabItem { Label(L10n.text("articles", app.language), systemImage: "newspaper") }
                    ImagesScreen()
                        .tabItem { Label(L10n.text("images", app.language), systemImage: "photo.on.rectangle") }
                    MoreScreen()
                        .tabItem { Label(L10n.text("more", app.language), systemImage: "ellipsis") }
                }
                .environmentObject(app)
                .tint(app.tint)
                .preferredColorScheme(app.colorScheme)
                .transition(.opacity)
            }
        }
    }
}

struct MoreScreen: View {
    @EnvironmentObject private var app: AppModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    MoreDestinationRow(
                        title: L10n.text("analytics", app.language),
                        subtitle: L10n.text("analyticsSubtitle", app.language),
                        systemImage: "chart.bar.xaxis",
                        tint: .blue
                    ) {
                        AnalyticsScreen()
                    }
                    MoreDestinationRow(
                        title: L10n.text("videos", app.language),
                        subtitle: L10n.text("videosSubtitle", app.language),
                        systemImage: "play.rectangle.fill",
                        tint: .red
                    ) {
                        VideosScreen()
                    }
                    MoreDestinationRow(
                        title: L10n.text("audios", app.language),
                        subtitle: L10n.text("audiosSubtitle", app.language),
                        systemImage: "music.note.list",
                        tint: .purple
                    ) {
                        AudiosScreen()
                    }
                    MoreDestinationRow(
                        title: L10n.text("files", app.language),
                        subtitle: L10n.text("filesSubtitle", app.language),
                        systemImage: "doc.richtext.fill",
                        tint: .teal
                    ) {
                        FilesScreen()
                    }
                } header: {
                    Text(L10n.text("library", app.language))
                }

                Section {
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
                } header: {
                    Text(L10n.text("settings", app.language))
                }
            }
            .navigationTitle(L10n.text("more", app.language))
        }
    }
}

private struct MoreDestinationRow<Destination: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(tint.gradient, in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 4)
        }
    }
}


#Preview {
    RootView()
}
