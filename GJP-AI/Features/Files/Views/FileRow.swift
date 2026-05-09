import SwiftUI

struct FileRow: View {
    @EnvironmentObject private var app: AppModel
    let item: FileItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.fill")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 44, height: 44)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
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
                }
                .accessibilityLabel("\(L10n.text("download", app.language)) \(item.name)")
            }
        }
    }
}
