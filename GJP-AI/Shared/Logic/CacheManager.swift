import Foundation

enum CacheManager {
    private static let folderName = "gjp_cache"

    private static func getCacheDirectory() -> URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(folderName)
    }

    static func save<T: Encodable>(_ items: [T], forKey key: String) {
        guard let directory = getCacheDirectory() else { return }
        
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        let fileURL = directory.appendingPathComponent("\(key).json")
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL)
        } catch {
            print("Cache save error for \(key): \(error)")
        }
    }

    static func load<T: Decodable>(forKey key: String) -> [T]? {
        guard let directory = getCacheDirectory() else { return nil }
        let fileURL = directory.appendingPathComponent("\(key).json")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            print("Cache load error for \(key): \(error)")
            return nil
        }
    }
}
