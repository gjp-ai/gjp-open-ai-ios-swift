import UIKit
import Foundation

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
    private let manifestURL: URL?

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
        self.manifestURL = cacheDirectory?.appendingPathComponent("manifest.json")

        let config = URLSessionConfiguration.default
        config.urlCache = urlCache
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
    }

    private func normalizedURL(_ url: URL) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        // Normalize URL to prevent duplicate caching of the same image with different temp params (tokens, versions, etc)
        let transientParams = ["token", "v", "t", "timestamp", "nonce", "_", "sig"]
        let queryItems = components?.queryItems
        components?.queryItems = queryItems?.filter { item in
            !transientParams.contains(item.name.lowercased())
        }
        return components?.url ?? url
    }

    /// Load an image, returning it from the in-memory cache instantly if available,
    /// otherwise fetching from the disk cache or network.
    func image(for url: URL) async throws -> UIImage {
        let key = url as NSURL
        if let cached = memory.object(forKey: key) {
            return cached
        }

        let data = try await self.data(for: url)
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        memory.setObject(image, forKey: key, cost: data.count)
        return image
    }

    func data(for url: URL) async throws -> Data {
        let normalized = normalizedURL(url)
        let request = URLRequest(url: normalized,
                                 cachePolicy: .returnCacheDataElseLoad,
                                 timeoutInterval: 30)

        // 1. Check disk cache first
        if let cachedResponse = urlCache.cachedResponse(for: request) {
            return cachedResponse.data
        }

        // 2. Fetch from network
        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            let cacheableResponse = CachedURLResponse(response: httpResponse,
                                                      data: data,
                                                      storagePolicy: .allowed)
            urlCache.storeCachedResponse(cacheableResponse, for: request)
            
            // Record in manifest to help user identify the image later
            // We record the newest file in the directory as the one just saved
            recordLastFile(for: url.absoluteString)
        }

        return data
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
        Task(priority: .background) { [weak self] in
            guard let self else { return }
            for url in urls {
                if self.memory.object(forKey: url as NSURL) != nil { continue }
                _ = try? await self.image(for: url)
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
        if let url = manifestURL {
            try? FileManager.default.removeItem(at: url)
        }
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
        let originalURL: String?
    }

    func allCachedFiles() -> [CachedFile] {
        guard let directory = getCacheDirectory()?.appendingPathComponent("fsCachedData") else { return [] }
        let manifest = loadManifest()
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        
        let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys, options: .skipsHiddenFiles)
        
        return files?.compactMap { fileURL -> CachedFile? in
            let resources = try? fileURL.resourceValues(forKeys: Set(keys))
            let filename = fileURL.lastPathComponent
            return CachedFile(
                id: filename,
                url: fileURL,
                size: Int64(resources?.fileSize ?? 0),
                date: resources?.contentModificationDate ?? Date(),
                originalURL: manifest[filename]
            )
        }.sorted { $0.date > $1.date } ?? []
    }

    // MARK: - Manifest management

    private func recordLastFile(for url: String) {
        guard let directory = getCacheDirectory()?.appendingPathComponent("fsCachedData"),
              let manifestURL = manifestURL else { return }
        
        // Find the newest file in the cache directory - it's likely the one we just saved
        let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)
        let newest = files?.compactMap { fileURL -> (URL, Date)? in
            let date = (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
            return date.map { (fileURL, $0) }
        }.sorted { $0.1 > $1.1 }.first?.0
        
        guard let filename = newest?.lastPathComponent else { return }
        
        var current = loadManifest()
        current[filename] = url
        if let data = try? JSONEncoder().encode(current) {
            try? data.write(to: manifestURL)
        }
    }

    private func loadManifest() -> [String: String] {
        guard let url = manifestURL,
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return manifest
    }
}
