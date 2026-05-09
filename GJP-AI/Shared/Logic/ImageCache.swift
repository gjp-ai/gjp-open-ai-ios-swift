import UIKit

/// A two-level (memory + disk) image cache that deliberately ignores
/// server-sent `Cache-Control: no-store` headers.
final class ImageCache {
    static let websites = ImageCache(namespace: "websites", diskCapacity: 50 * 1024 * 1024)
    static let articles = ImageCache(namespace: "articles", diskCapacity: 100 * 1024 * 1024)
    static let media = ImageCache(namespace: "media", diskCapacity: 200 * 1024 * 1024)

    // MARK: Memory cache (shared cost limit across instances is fine, or per instance)
    private let memory = NSCache<NSURL, UIImage>()

    // MARK: Disk cache via a dedicated URLCache
    private let namespace: String
    private let urlCache: URLCache
    private let session: URLSession

    private init(namespace: String, diskCapacity: Int) {
        self.namespace = namespace
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("gjp_image_cache")
            .appendingPathComponent(namespace)

        // 20 MB memory per instance, custom disk capacity
        urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024,
                            diskCapacity: diskCapacity,
                            directory: cacheDirectory)
        memory.totalCostLimit = 20 * 1024 * 1024

        let config = URLSessionConfiguration.default
        config.urlCache = urlCache
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
    }

    /// Load an image, returning it from the in-memory cache instantly if available,
    /// otherwise fetching from the disk cache or network.
    func image(for url: URL) async throws -> UIImage {
        let key = url as NSURL

        if let cached = memory.object(forKey: key) {
            return cached
        }

        let request = URLRequest(url: url,
                                 cachePolicy: .returnCacheDataElseLoad,
                                 timeoutInterval: 30)

        let (data, response) = try await session.data(for: request)

        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }

        if let httpResponse = response as? HTTPURLResponse {
            let cacheableResponse = CachedURLResponse(response: httpResponse,
                                                      data: data,
                                                      storagePolicy: .allowed)
            urlCache.storeCachedResponse(cacheableResponse, for: request)
        }

        let cost = data.count
        memory.setObject(image, forKey: key, cost: cost)

        return image
    }

    // MARK: - Shared URL parser

    static func parsedURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil { return url }
        if let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
           let url = URL(string: encoded), url.scheme != nil { return url }
        return nil
    }

    // MARK: - Background prefetch

    func prefetch(urlStrings: [String]) {
        let urls = urlStrings.compactMap { ImageCache.parsedURL(from: $0) }
        guard !urls.isEmpty else { return }
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            for url in urls {
                if self.memory.object(forKey: url as NSURL) != nil { continue }
                try? await self.image(for: url)
            }
        }
    }

    // MARK: - Management

    var diskSize: Int {
        urlCache.currentDiskUsage
    }

    var lastModified: Date? {
        guard let directory = getCacheDirectory() else { return nil }
        let attributes = try? FileManager.default.attributesOfItem(atPath: directory.path)
        return attributes?[.modificationDate] as? Date
    }

    func clear() {
        memory.removeAllObjects()
        urlCache.removeAllCachedResponses()
    }

    private func getCacheDirectory() -> URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("gjp_image_cache")
            .appendingPathComponent(namespace)
    }

    struct CachedFile: Identifiable {
        let id: String
        let url: URL
        let size: Int64
        let date: Date
    }

    func allCachedFiles() -> [CachedFile] {
        guard let directory = getCacheDirectory()?.appendingPathComponent("fsCachedData") else { return [] }
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        
        let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys, options: .skipsHiddenFiles)
        
        return files?.compactMap { fileURL -> CachedFile? in
            let resources = try? fileURL.resourceValues(forKeys: Set(keys))
            return CachedFile(
                id: fileURL.lastPathComponent,
                url: fileURL,
                size: Int64(resources?.fileSize ?? 0),
                date: resources?.contentModificationDate ?? Date()
            )
        }.sorted { $0.date > $1.date } ?? []
    }
}
