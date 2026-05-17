import SwiftUI

struct AppConfigSettingsScreen: View {
    @EnvironmentObject private var app: AppModel
    
    @AppStorage("AppConfig.Cache.listFreshnessDuration") private var listFreshnessDuration: Double = 30 * 60
    @AppStorage("AppConfig.Cache.Media.websitesCapacity") private var websitesCapacity: Int = 50 * 1024 * 1024
    @AppStorage("AppConfig.Cache.Media.articlesCapacity") private var articlesCapacity: Int = 100 * 1024 * 1024
    @AppStorage("AppConfig.Cache.Media.mediaNamespace") private var mediaNamespace: String = "media"
    @AppStorage("AppConfig.Cache.Media.videosNamespace") private var videosNamespace: String = "videos"
    @AppStorage("AppConfig.Cache.Media.audiosNamespace") private var audiosNamespace: String = "audios"

    var body: some View {
        List {
            Section {
                DetailRow(label: "Base URL", value: AppConfig.API.baseURL.absoluteString)
            } header: {
                Text("API Configuration")
            }

            Section {
                HStack {
                    Text("Cache Duration")
                    Spacer()
                    TextField("Minutes", value: Binding(
                        get: { Int(listFreshnessDuration / 60) },
                        set: { listFreshnessDuration = Double($0) * 60 }
                    ), formatter: NumberFormatter())
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    Text("min")
                        .foregroundStyle(.secondary)
                }
                DetailRow(label: "Data Folder", value: AppConfig.Cache.folderName)
            } header: {
                Text("Database Policies")
            }

            Section {
                Group {
                    EditableCapacityRow(label: "Websites Capacity", value: $websitesCapacity)
                    EditableCapacityRow(label: "Articles Capacity", value: $articlesCapacity)
                    
                    EditableNamespaceRow(label: "Media Namespace", value: $mediaNamespace)
                    EditableNamespaceRow(label: "Videos Namespace", value: $videosNamespace)
                    EditableNamespaceRow(label: "Audios Namespace", value: $audiosNamespace)
                }
            } header: {
                Text("Media Cache Policies")
            }
            
            Section {
                Text("Changes to namespaces or capacities will take full effect after an app restart or cache reload.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("App Config")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct EditableCapacityRow: View {
    let label: String
    @Binding var value: Int
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("MB", value: Binding(
                get: { value / 1024 / 1024 },
                set: { value = $0 * 1024 * 1024 }
            ), formatter: NumberFormatter())
            .multilineTextAlignment(.trailing)
            .keyboardType(.numberPad)
            Text("MB")
                .foregroundStyle(.secondary)
        }
    }
}

private struct EditableNamespaceRow: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("Namespace", text: $value)
                .multilineTextAlignment(.trailing)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
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
