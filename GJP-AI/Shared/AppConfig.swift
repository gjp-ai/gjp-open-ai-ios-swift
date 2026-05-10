import Foundation

/// Centralized configuration for the application
enum AppConfig {
    
    // MARK: - API Configuration
    
    enum API {
        /// The base URL for all open API requests
        static let baseURL = URL(string: "https://www.ganjianping.com/api/open")!
    }
    
    // MARK: - Pagination Settings
    
    enum Pagination {
        /// Standard number of items to load per page for most lists (Articles, Media, Files)
        static let defaultPageSize = 50
        
        /// Larger page size for lightweight items (Questions, Websites)
        static let largePageSize = 100
    }
    
    // MARK: - Cache Policies
    
    enum Cache {
        /// Duration before the app will attempt a background refresh for cached list data
        static let listFreshnessDuration: TimeInterval = 30 * 60 // 30 minutes
        
        /// Directory name for general application cache
        static let folderName = "gjp_cache"
    }
}
