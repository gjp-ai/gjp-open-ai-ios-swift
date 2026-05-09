import SwiftUI

struct AnalyticsMetric: Identifiable, Equatable {
    let kind: AnalyticsKind
    let total: Int

    var id: AnalyticsKind { kind }
}

enum AnalyticsKind: CaseIterable {
    case websites
    case questions
    case articles
    case images
    case videos
    case audios
    case files

    var systemImage: String {
        switch self {
        case .websites: "globe"
        case .questions: "questionmark.circle.fill"
        case .articles: "newspaper.fill"
        case .images: "photo.on.rectangle.angled"
        case .videos: "play.rectangle.fill"
        case .audios: "music.note.list"
        case .files: "doc.richtext.fill"
        }
    }

    var tint: Color {
        switch self {
        case .websites: .blue
        case .questions: .indigo
        case .articles: .orange
        case .images: .green
        case .videos: .red
        case .audios: .purple
        case .files: .teal
        }
    }

    func title(language: LanguageCode) -> String {
        switch self {
        case .websites: L10n.text("websites", language)
        case .questions: L10n.text("questions", language)
        case .articles: L10n.text("articles", language)
        case .images: L10n.text("images", language)
        case .videos: L10n.text("videos", language)
        case .audios: L10n.text("audios", language)
        case .files: L10n.text("files", language)
        }
    }
}
