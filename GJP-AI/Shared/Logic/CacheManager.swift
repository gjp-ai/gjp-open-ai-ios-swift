import Foundation

enum CacheManager {
    private static let folderName = "gjp_cache"

    private static func getCacheDirectory() -> URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(folderName)
    }

    private static func ensureDirectory() -> URL? {
        guard let directory = getCacheDirectory() else { return nil }
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    // MARK: - Array cache (used by OpenListViewModel)

    static func save<T: Encodable>(_ items: [T], forKey key: String) {
        guard let directory = ensureDirectory() else { return }
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

    // MARK: - Single-item cache (used for ArticleDetail)

    static func saveItem<T: Encodable>(_ item: T, forKey key: String) {
        guard let directory = ensureDirectory() else { return }
        let fileURL = directory.appendingPathComponent("\(key).json")
        do {
            let data = try JSONEncoder().encode(item)
            try data.write(to: fileURL)
        } catch {
            print("Cache saveItem error for \(key): \(error)")
        }
    }

    static func loadItem<T: Decodable>(forKey key: String) -> T? {
        guard let directory = getCacheDirectory() else { return nil }
        let fileURL = directory.appendingPathComponent("\(key).json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Cache loadItem error for \(key): \(error)")
            return nil
        }
    }

    // MARK: - Management

    static func size(forKey key: String) -> Int64 {
        guard let directory = getCacheDirectory() else { return 0 }
        let fileURL = directory.appendingPathComponent("\(key).json")
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        return attributes?[.size] as? Int64 ?? 0
    }

    static func clear(forKey key: String) {
        guard let directory = getCacheDirectory() else { return }
        let fileURL = directory.appendingPathComponent("\(key).json")
        try? FileManager.default.removeItem(at: fileURL)
    }

    static func clearAll() {
        guard let directory = getCacheDirectory() else { return }
        try? FileManager.default.removeItem(at: directory)
    }

    static func lastModified(forKey key: String) -> Date? {
        guard let directory = getCacheDirectory() else { return nil }
        let fileURL = directory.appendingPathComponent("\(key).json")
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        return attributes?[.modificationDate] as? Date
    }

    static func loadRaw(forKey key: String) -> String? {
        guard let directory = getCacheDirectory() else { return nil }
        let fileURL = directory.appendingPathComponent("\(key).json")
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
