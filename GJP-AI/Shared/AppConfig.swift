import Foundation

/// Centralized configuration for the application
enum AppConfig {
    
    // MARK: - API Configuration
    
    enum API {
        /// The base URL for all open API requests
        static let baseURL = URL(string: "https://www.ganjianping.com/api/open")!
        
        /// Timeout for network requests in seconds
        static let timeoutInterval: TimeInterval = 30
    }
    
    
    // MARK: - Cache Policies
    
    enum Cache {
        /// Duration before the app will attempt a background refresh for cached list data
        static let listFreshnessDuration: TimeInterval = 30 * 60 // 30 minutes
        
        /// Directory name for general application cache
        static let folderName = "gjp_cache"

        enum Media {
            static let websitesCapacity: Int = 50 * 1024 * 1024
            static let articlesCapacity: Int = 100 * 1024 * 1024
            static let mediaCapacity: Int = 200 * 1024 * 1024
            static let videosCapacity: Int = 500 * 1024 * 1024
            static let audiosCapacity: Int = 200 * 1024 * 1024
            
            static let memoryCapacity: Int = 20 * 1024 * 1024
            
            static let websitesNamespace = "websites"
            static let articlesNamespace = "articles"
            static let mediaNamespace = "media"
            static let videosNamespace = "videos"
            static let audiosNamespace = "audios"

            static let rootFolderName = "gjp_media_cache"
            static let manifestFileName = "manifest.json"
        }
    }
}
