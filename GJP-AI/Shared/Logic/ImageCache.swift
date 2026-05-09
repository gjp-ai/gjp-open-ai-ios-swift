import UIKit

// MARK: - ImageCache

/// A two-level (memory + disk) image cache that deliberately ignores
/// server-sent `Cache-Control: no-store` headers.
/// This is necessary because the API server returns `no-cache, no-store`
/// on all image responses, which prevents `AsyncImage` / `URLSession` from
/// ever caching images — causing blank images on every scroll/reuse.
final class ImageCache {
    static let shared = ImageCache()

    // MARK: Memory cache
    private let memory = NSCache<NSURL, UIImage>()

    // MARK: Disk cache via a dedicated URLCache that ignores cache directives
    private let urlCache: URLCache
    private let session: URLSession

    private init() {
        // 50 MB memory, 200 MB disk — enough to hold a full screen of images
        urlCache = URLCache(memoryCapacity: 50 * 1024 * 1024,
                            diskCapacity: 200 * 1024 * 1024)
        memory.totalCostLimit = 50 * 1024 * 1024

        let config = URLSessionConfiguration.default
        config.urlCache = urlCache
        // Use .returnCacheDataElseLoad so we serve from cache even when
        // the server says no-store.  On first load the request is made
        // normally and we manually store the result ourselves.
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
    }

    /// Load an image, returning it from the in-memory cache instantly if available,
    /// otherwise fetching from the disk cache or network.
    func image(for url: URL) async throws -> UIImage {
        let key = url as NSURL

        // 1. Check in-memory cache (instant, no I/O)
        if let cached = memory.object(forKey: key) {
            return cached
        }

        // 2. Build the request — use .returnCacheDataElseLoad so our disk
        //    cache is consulted before hitting the network.
        let request = URLRequest(url: url,
                                 cachePolicy: .returnCacheDataElseLoad,
                                 timeoutInterval: 30)

        let (data, response) = try await session.data(for: request)

        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }

        // 3. Manually store in URLCache — this bypasses the server's
        //    Cache-Control: no-store directive, which is the root cause of
        //    images not persisting between scroll positions.
        if let httpResponse = response as? HTTPURLResponse {
            let cacheableResponse = CachedURLResponse(response: httpResponse,
                                                      data: data,
                                                      storagePolicy: .allowed)
            urlCache.storeCachedResponse(cacheableResponse, for: request)
        }

        // 4. Store in memory cache
        let cost = data.count
        memory.setObject(image, forKey: key, cost: cost)

        return image
    }

    // MARK: - Shared URL parser (used by RemoteImage and prefetch)

    /// Converts a raw URL string (possibly with spaces or unencoded chars) to a URL.
    static func parsedURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil { return url }
        if let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
           let url = URL(string: encoded), url.scheme != nil { return url }
        return nil
    }

    // MARK: - Background prefetch

    /// Warms the cache for a list of URL strings (e.g. from a JSON cache restore).
    /// Runs at background priority so it doesn't compete with the UI.
    func prefetch(urlStrings: [String]) {
        let urls = urlStrings.compactMap { ImageCache.parsedURL(from: $0) }
        guard !urls.isEmpty else { return }
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            for url in urls {
                // Skip if already in memory cache
                if self.memory.object(forKey: url as NSURL) != nil { continue }
                try? await self.image(for: url)
            }
        }
    }
}
