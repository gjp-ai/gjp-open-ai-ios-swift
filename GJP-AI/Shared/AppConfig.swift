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
        static var listFreshnessDuration: TimeInterval {
            get { 
                let val = UserDefaults.standard.double(forKey: "AppConfig.Cache.listFreshnessDuration")
                return val > 0 ? val : 30 * 60 
            }
            set { UserDefaults.standard.set(newValue, forKey: "AppConfig.Cache.listFreshnessDuration") }
        }
        
        /// Directory name for general application cache
        static let folderName = "gjp_cache"

        enum Media {
            static var websitesCapacity: Int {
                get { 
                    let val = UserDefaults.standard.integer(forKey: "AppConfig.Cache.Media.websitesCapacity")
                    return val > 0 ? val : 50 * 1024 * 1024 
                }
                set { UserDefaults.standard.set(newValue, forKey: "AppConfig.Cache.Media.websitesCapacity") }
            }
            
            static var articlesCapacity: Int {
                get { 
                    let val = UserDefaults.standard.integer(forKey: "AppConfig.Cache.Media.articlesCapacity")
                    return val > 0 ? val : 100 * 1024 * 1024 
                }
                set { UserDefaults.standard.set(newValue, forKey: "AppConfig.Cache.Media.articlesCapacity") }
            }
            
            static let mediaCapacity: Int = 200 * 1024 * 1024
            static let videosCapacity: Int = 500 * 1024 * 1024
            static let audiosCapacity: Int = 200 * 1024 * 1024
            
            static let memoryCapacity: Int = 20 * 1024 * 1024
            
            static var websitesNamespace: String {
                get { UserDefaults.standard.string(forKey: "AppConfig.Cache.Media.websitesNamespace") ?? "websites" }
                set { UserDefaults.standard.set(newValue, forKey: "AppConfig.Cache.Media.websitesNamespace") }
            }
            
            static var articlesNamespace: String {
                get { UserDefaults.standard.string(forKey: "AppConfig.Cache.Media.articlesNamespace") ?? "articles" }
                set { UserDefaults.standard.set(newValue, forKey: "AppConfig.Cache.Media.articlesNamespace") }
            }
            
            static var mediaNamespace: String {
                get { UserDefaults.standard.string(forKey: "AppConfig.Cache.Media.mediaNamespace") ?? "media" }
                set { UserDefaults.standard.set(newValue, forKey: "AppConfig.Cache.Media.mediaNamespace") }
            }
            
            static var videosNamespace: String {
                get { UserDefaults.standard.string(forKey: "AppConfig.Cache.Media.videosNamespace") ?? "videos" }
                set { UserDefaults.standard.set(newValue, forKey: "AppConfig.Cache.Media.videosNamespace") }
            }
            
            static var audiosNamespace: String {
                get { UserDefaults.standard.string(forKey: "AppConfig.Cache.Media.audiosNamespace") ?? "audios" }
                set { UserDefaults.standard.set(newValue, forKey: "AppConfig.Cache.Media.audiosNamespace") }
            }

            static let rootFolderName = "gjp_media_cache"
            static let manifestFileName = "manifest.json"
        }
    }
}
