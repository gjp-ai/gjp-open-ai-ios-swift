import SwiftUI

struct AppConfigSettingsScreen: View {
    @EnvironmentObject private var app: AppModel

    var body: some View {
        List {
            Section {
                DetailRow(label: "Base URL", value: AppConfig.API.baseURL.absoluteString)
            } header: {
                Text("API Configuration")
            }

            Section {
                DetailRow(label: "Cache Duration", value: "\(Int(AppConfig.Cache.listFreshnessDuration / 60)) minutes")
                DetailRow(label: "Data Folder", value: AppConfig.Cache.folderName)
            } header: {
                Text("Database Policies")
            }

            Section {
                let media = AppConfig.Cache.Media.self
                DetailRow(label: "Websites", value: "\(media.websitesNamespace) (\(media.websitesCapacity / 1024 / 1024)MB)")
                DetailRow(label: "Articles", value: "\(media.articlesNamespace) (\(media.articlesCapacity / 1024 / 1024)MB)")
                DetailRow(label: "Images", value: "\(media.mediaNamespace) (\(media.mediaCapacity / 1024 / 1024)MB)")
                DetailRow(label: "Videos", value: "\(media.videosNamespace) (\(media.videosCapacity / 1024 / 1024)MB)")
                DetailRow(label: "Audios", value: "\(media.audiosNamespace) (\(media.audiosCapacity / 1024 / 1024)MB)")
            } header: {
                Text("Media Cache Policies")
            }
            
            Section {
                Text("These settings are compile-time constants used to configure the app's networking and persistence behavior.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("App Config")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.monospaced())
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }
}
