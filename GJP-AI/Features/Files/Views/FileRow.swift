import SwiftUI

struct FileRow: View {
    @EnvironmentObject private var app: AppModel
    let item: FileItem

    private var fileIcon: String {
        let name = item.name.lowercased()
        if name.hasSuffix(".pdf") { return "doc.text.fill" }
        if name.hasSuffix(".doc") || name.hasSuffix(".docx") { return "doc.richtext.fill" }
        if name.hasSuffix(".xls") || name.hasSuffix(".xlsx") || name.hasSuffix(".csv") { return "tablecells.fill" }
        if name.hasSuffix(".ppt") || name.hasSuffix(".pptx") { return "rectangle.fill.on.rectangle.fill" }
        if name.hasSuffix(".zip") || name.hasSuffix(".rar") || name.hasSuffix(".7z") { return "doc.zipper" }
        if name.hasSuffix(".jpg") || name.hasSuffix(".jpeg") || name.hasSuffix(".png") || name.hasSuffix(".gif") || name.hasSuffix(".webp") { return "photo.fill" }
        if name.hasSuffix(".mp3") || name.hasSuffix(".wav") || name.hasSuffix(".aac") || name.hasSuffix(".m4a") { return "music.note" }
        if name.hasSuffix(".mp4") || name.hasSuffix(".mov") || name.hasSuffix(".avi") { return "film.fill" }
        if name.hasSuffix(".txt") || name.hasSuffix(".md") { return "doc.plaintext.fill" }
        if name.hasSuffix(".json") || name.hasSuffix(".xml") { return "curlybraces" }
        return "doc.fill"
    }

    private var iconTint: Color {
        let name = item.name.lowercased()
        if name.hasSuffix(".pdf") { return .red }
        if name.hasSuffix(".doc") || name.hasSuffix(".docx") { return .blue }
        if name.hasSuffix(".xls") || name.hasSuffix(".xlsx") || name.hasSuffix(".csv") { return .green }
        if name.hasSuffix(".ppt") || name.hasSuffix(".pptx") { return .orange }
        if name.hasSuffix(".zip") || name.hasSuffix(".rar") || name.hasSuffix(".7z") { return .brown }
        return .teal
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: fileIcon)
                .font(.title3)
                .foregroundStyle(iconTint)
                .frame(width: 44, height: 44)
                .background(iconTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)
                if let description = item.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                TagFlow(tags: item.tags)
            }
            Spacer()
            if let urlString = item.url, let url = URL(string: urlString) {
                Link(destination: url) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                }
                .accessibilityLabel("\(L10n.text("download", app.language)) \(item.name)")
            }
        }
    }
}
