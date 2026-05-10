import Foundation
import SQLite3

struct SQLiteContentStats: Equatable {
    let key: String
    let count: Int
    let size: Int64
    let lastModified: Date?
}

struct SQLiteContentRow: Identifiable, Equatable {
    let id: String
    let lang: String
    let title: String
    let tags: String?
    let displayOrder: Int
    let updatedAt: String
    let syncedAt: Double
    let json: String
    let size: Int64
}

final class SQLiteContentStore<Item: OpenListItem> {
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let queue: DispatchQueue

    init(key: String) {
        self.key = key
        self.queue = DispatchQueue(label: "gjp.sqlite-content-store.\(key)")
        SQLiteContentDatabase.shared.initialize()
    }

    func save(_ items: [Item], language: LanguageCode, replaceExisting: Bool, successfulSyncDate: String) {
        queue.sync {
            SQLiteContentDatabase.shared.save(
                items,
                key: key,
                language: language,
                replaceExisting: replaceExisting,
                successfulSyncDate: successfulSyncDate,
                encoder: encoder
            )
        }
    }

    func query(language: LanguageCode, search: String?, tag: String?, sortOrder: SortOrder) -> [Item] {
        queue.sync {
            SQLiteContentDatabase.shared.query(
                key: key,
                language: language,
                search: search,
                tag: tag,
                sortOrder: sortOrder,
                decoder: decoder
            )
        }
    }

    func lastModified(language: LanguageCode) -> Date? {
        queue.sync {
            SQLiteContentDatabase.shared.lastModified(key: key, language: language)
        }
    }

    func count(language: LanguageCode) -> Int {
        queue.sync {
            SQLiteContentDatabase.shared.count(key: key, language: language)
        }
    }

    func updatedAfter(language: LanguageCode) -> String? {
        queue.sync {
            SQLiteContentDatabase.shared.updatedAfter(key: key, language: language)
        }
    }
}

final class SQLiteContentDatabase {
    static let shared = SQLiteContentDatabase()

    private let databaseURL: URL
    private let queue = DispatchQueue(label: "gjp.sqlite-content-database")
    private var didInitialize = false

    var totalFileSize: Int64 {
        let attrs = try? FileManager.default.attributesOfItem(atPath: databaseURL.path)
        return attrs?[.size] as? Int64 ?? 0
    }

    private init() {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = baseURL.appendingPathComponent("GJP-AI", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        databaseURL = directory.appendingPathComponent("content-cache.sqlite")
    }

    static func syncDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.string(from: date)
    }

    func initialize() {
        queue.sync {
            guard !didInitialize else { return }
            withDatabase { db in
                execute("""
                CREATE TABLE IF NOT EXISTS content_items (
                    resource_key TEXT NOT NULL,
                    lang TEXT NOT NULL,
                    id TEXT NOT NULL,
                    tags TEXT,
                    searchable_text TEXT NOT NULL,
                    sort_title TEXT NOT NULL,
                    display_order INTEGER NOT NULL,
                    updated_at TEXT NOT NULL,
                    json TEXT NOT NULL,
                    synced_at REAL NOT NULL,
                    PRIMARY KEY(resource_key, lang, id)
                );
                """, db: db)
                execute("CREATE INDEX IF NOT EXISTS idx_content_lang_key ON content_items(resource_key, lang);", db: db)
                execute("CREATE INDEX IF NOT EXISTS idx_content_updated ON content_items(resource_key, lang, updated_at);", db: db)
                execute("CREATE INDEX IF NOT EXISTS idx_content_sort ON content_items(resource_key, lang, display_order, sort_title);", db: db)
                execute("""
                CREATE TABLE IF NOT EXISTS content_sync (
                    resource_key TEXT NOT NULL,
                    lang TEXT NOT NULL,
                    updated_after TEXT NOT NULL,
                    synced_at REAL NOT NULL,
                    PRIMARY KEY(resource_key, lang)
                );
                """, db: db)
            }
            didInitialize = true
        }
    }

    func save<Item: OpenListItem>(
        _ items: [Item],
        key: String,
        language: LanguageCode, // The primary language that triggered the sync
        replaceExisting: Bool,
        successfulSyncDate: String,
        encoder: JSONEncoder
    ) {
        initialize()
        queue.sync {
            withDatabase { db in
                execute("BEGIN IMMEDIATE TRANSACTION;", db: db)
                
                // If full sync (replaceExisting), we clear the local cache for this resource
                if replaceExisting {
                    execute("DELETE FROM content_items WHERE resource_key = ?;", db: db, bindings: [key])
                }

                let sql = """
                INSERT OR REPLACE INTO content_items
                (resource_key, lang, id, tags, searchable_text, sort_title, display_order, updated_at, json, synced_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
                """
                var statement: OpaquePointer?
                guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                    execute("ROLLBACK;", db: db)
                    return
                }
                defer { sqlite3_finalize(statement) }

                let syncedAt = Date().timeIntervalSince1970
                var syncedLanguages = Set<String>()
                syncedLanguages.insert(language.rawValue)

                for item in items {
                    guard let data = try? encoder.encode(item),
                          let json = String(data: data, encoding: .utf8) else { continue }
                    
                    syncedLanguages.insert(item.lang.rawValue)
                    
                    sqlite3_reset(statement)
                    sqlite3_clear_bindings(statement)
                    bindText(key, to: 1, statement: statement)
                    bindText(item.lang.rawValue, to: 2, statement: statement)
                    bindText(item.id, to: 3, statement: statement)
                    bindText(item.tags, to: 4, statement: statement)
                    bindText(item.searchableText, to: 5, statement: statement)
                    bindText(item.sortTitle, to: 6, statement: statement)
                    sqlite3_bind_int(statement, 7, Int32(item.displayOrder))
                    bindText(item.updatedAt, to: 8, statement: statement)
                    bindText(json, to: 9, statement: statement)
                    sqlite3_bind_double(statement, 10, syncedAt)
                    _ = sqlite3_step(statement)
                }

                // Update sync tracking for all languages that were updated
                for lang in syncedLanguages {
                    execute("""
                    INSERT OR REPLACE INTO content_sync (resource_key, lang, updated_after, synced_at)
                    VALUES (?, ?, ?, ?);
                    """, db: db, bindings: [
                        key,
                        lang,
                        successfulSyncDate,
                        String(syncedAt)
                    ])
                }
                
                execute("COMMIT;", db: db)
            }
        }
    }

    func query<Item: OpenListItem>(
        key: String,
        language: LanguageCode,
        search: String?,
        tag: String?,
        sortOrder: SortOrder,
        decoder: JSONDecoder
    ) -> [Item] {
        initialize()
        return queue.sync {
            withDatabaseResult(defaultValue: []) { db in
                var sql = "SELECT json FROM content_items WHERE resource_key = ? AND lang = ?"
                var bindings: [String?] = [key, language.rawValue]

                if let trimmed = search?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty {
                    sql += " AND searchable_text LIKE ? ESCAPE '\\'"
                    bindings.append("%\(escapeLike(trimmed))%")
                }

                if let trimmedTag = tag?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmedTag.isEmpty {
                    sql += " AND (',' || REPLACE(tags, ' ', '') || ',') LIKE ?"
                    bindings.append("%,\(trimmedTag.replacingOccurrences(of: " ", with: "")),%")
                }

                switch sortOrder {
                case .displayOrder:
                    sql += " ORDER BY display_order ASC, sort_title COLLATE NOCASE ASC"
                case .alpha:
                    sql += " ORDER BY sort_title COLLATE NOCASE ASC"
                case .recent:
                    sql += " ORDER BY updated_at DESC, display_order ASC"
                }

                var statement: OpaquePointer?
                guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return [] }
                defer { sqlite3_finalize(statement) }

                for (index, binding) in bindings.enumerated() {
                    bindText(binding, to: Int32(index + 1), statement: statement)
                }

                var result: [Item] = []
                while sqlite3_step(statement) == SQLITE_ROW {
                    guard let value = sqlite3_column_text(statement, 0) else { continue }
                    let json = String(cString: value)
                    guard let data = json.data(using: .utf8),
                          let item = try? decoder.decode(Item.self, from: data) else { continue }
                    result.append(item)
                }
                return result
            }
        }
    }

    func stats(for keys: [String]) -> [String: SQLiteContentStats] {
        initialize()
        return queue.sync {
            var result: [String: SQLiteContentStats] = [:]
            for key in keys {
                let count = countUnlocked(key: key, language: nil)
                let size = sizeUnlocked(key: key, language: nil)
                let date = lastModifiedUnlocked(key: key, language: nil)
                result[key] = SQLiteContentStats(key: key, count: count, size: size, lastModified: date)
            }
            return result
        }
    }

    func rows(for key: String) -> [SQLiteContentRow] {
        initialize()
        return queue.sync {
            withDatabaseResult(defaultValue: []) { db in
                let sql = """
                SELECT lang, id, sort_title, tags, display_order, updated_at, synced_at, json, LENGTH(json)
                FROM content_items
                WHERE resource_key = ?
                ORDER BY lang ASC, display_order ASC, sort_title COLLATE NOCASE ASC;
                """
                var statement: OpaquePointer?
                guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return [] }
                defer { sqlite3_finalize(statement) }
                bindText(key, to: 1, statement: statement)

                var result: [SQLiteContentRow] = []
                while sqlite3_step(statement) == SQLITE_ROW {
                    let language = sqlite3_column_text(statement, 0).map { String(cString: $0) } ?? ""
                    let id = sqlite3_column_text(statement, 1).map { String(cString: $0) } ?? ""
                    let title = sqlite3_column_text(statement, 2).map { String(cString: $0) } ?? ""
                    let tags = sqlite3_column_text(statement, 3).map { String(cString: $0) } ?? ""
                    let displayOrder = Int(sqlite3_column_int(statement, 4))
                    let updatedAt = sqlite3_column_text(statement, 5).map { String(cString: $0) } ?? ""
                    let syncedAt = sqlite3_column_double(statement, 6)
                    let json = sqlite3_column_text(statement, 7).map { String(cString: $0) } ?? ""
                    let size = sqlite3_column_int64(statement, 8)
                    result.append(SQLiteContentRow(id: id, lang: language, title: title, tags: tags, displayOrder: displayOrder, updatedAt: updatedAt, syncedAt: syncedAt, json: json, size: size))
                }
                return result
            }
        }
    }

    func rowSummary(for key: String) -> String {
        initialize()
        return queue.sync {
            withDatabaseResult(defaultValue: "No data found.") { db in
                let sql = """
                SELECT lang, id, sort_title, tags, updated_at, LENGTH(json)
                FROM content_items
                WHERE resource_key = ?
                ORDER BY lang ASC, display_order ASC, sort_title COLLATE NOCASE ASC;
                """
                var statement: OpaquePointer?
                guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return "No data found." }
                defer { sqlite3_finalize(statement) }
                bindText(key, to: 1, statement: statement)

                var text = ""
                var currentLanguage: String?
                while sqlite3_step(statement) == SQLITE_ROW {
                    let language = sqlite3_column_text(statement, 0).map { String(cString: $0) } ?? ""
                    let id = sqlite3_column_text(statement, 1).map { String(cString: $0) } ?? ""
                    let title = sqlite3_column_text(statement, 2).map { String(cString: $0) } ?? ""
                    let tags = sqlite3_column_text(statement, 3).map { String(cString: $0) } ?? ""
                    let updatedAt = sqlite3_column_text(statement, 4).map { String(cString: $0) } ?? ""
                    let size = sqlite3_column_int64(statement, 5)
                    if currentLanguage != language {
                        if !text.isEmpty { text += "\n" }
                        text += "--- \(language) ---\n"
                        currentLanguage = language
                    }
                    text += """
                    id: \(id)
                    title: \(title)
                    tags: \(tags)
                    updatedAt: \(updatedAt)
                    storedBytes: \(size)

                    """
                }
                return text.isEmpty ? "No data found." : text
            }
        }
    }

    func clear(key: String) {
        initialize()
        queue.sync {
            withDatabase { db in
                execute("DELETE FROM content_items WHERE resource_key = ?;", db: db, bindings: [key])
                execute("DELETE FROM content_sync WHERE resource_key = ?;", db: db, bindings: [key])
            }
        }
    }

    func clearAll() {
        initialize()
        queue.sync {
            withDatabase { db in
                execute("DELETE FROM content_items;", db: db)
                execute("DELETE FROM content_sync;", db: db)
            }
        }
    }

    func lastModified(key: String, language: LanguageCode) -> Date? {
        initialize()
        return queue.sync { lastModifiedUnlocked(key: key, language: language.rawValue) }
    }

    func count(key: String, language: LanguageCode) -> Int {
        initialize()
        return queue.sync { countUnlocked(key: key, language: language.rawValue) }
    }

    func updatedAfter(key: String, language: LanguageCode) -> String? {
        initialize()
        return queue.sync {
            withDatabaseResult(defaultValue: nil) { db in
                let sql = "SELECT updated_after FROM content_sync WHERE resource_key = ? AND lang = ?;"
                var statement: OpaquePointer?
                guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
                defer { sqlite3_finalize(statement) }
                bindText(key, to: 1, statement: statement)
                bindText(language.rawValue, to: 2, statement: statement)
                guard sqlite3_step(statement) == SQLITE_ROW,
                      let value = sqlite3_column_text(statement, 0) else { return nil }
                return String(cString: value)
            }
        }
    }

    var databaseSize: Int64 {
        (try? FileManager.default.attributesOfItem(atPath: databaseURL.path)[.size] as? Int64) ?? 0
    }

    private func countUnlocked(key: String, language: String?) -> Int {
        withDatabaseResult(defaultValue: 0) { db in
            let sql = language == nil
                ? "SELECT COUNT(*) FROM content_items WHERE resource_key = ?;"
                : "SELECT COUNT(*) FROM content_items WHERE resource_key = ? AND lang = ?;"
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return 0 }
            defer { sqlite3_finalize(statement) }
            bindText(key, to: 1, statement: statement)
            if let language {
                bindText(language, to: 2, statement: statement)
            }
            guard sqlite3_step(statement) == SQLITE_ROW else { return 0 }
            return Int(sqlite3_column_int(statement, 0))
        }
    }

    private func sizeUnlocked(key: String, language: String?) -> Int64 {
        withDatabaseResult(defaultValue: 0) { db in
            let sql = language == nil
                ? "SELECT COALESCE(SUM(LENGTH(json)), 0) FROM content_items WHERE resource_key = ?;"
                : "SELECT COALESCE(SUM(LENGTH(json)), 0) FROM content_items WHERE resource_key = ? AND lang = ?;"
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return 0 }
            defer { sqlite3_finalize(statement) }
            bindText(key, to: 1, statement: statement)
            if let language {
                bindText(language, to: 2, statement: statement)
            }
            guard sqlite3_step(statement) == SQLITE_ROW else { return 0 }
            return sqlite3_column_int64(statement, 0)
        }
    }

    private func lastModifiedUnlocked(key: String, language: String?) -> Date? {
        withDatabaseResult(defaultValue: nil) { db in
            let sql = language == nil
                ? "SELECT MAX(synced_at) FROM content_sync WHERE resource_key = ?;"
                : "SELECT MAX(synced_at) FROM content_sync WHERE resource_key = ? AND lang = ?;"
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
            defer { sqlite3_finalize(statement) }
            bindText(key, to: 1, statement: statement)
            if let language {
                bindText(language, to: 2, statement: statement)
            }
            guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
            let timestamp = sqlite3_column_double(statement, 0)
            return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
        }
    }

    private func withDatabase(_ work: (OpaquePointer?) -> Void) {
        var db: OpaquePointer?
        guard sqlite3_open(databaseURL.path, &db) == SQLITE_OK else { return }
        defer { sqlite3_close(db) }
        work(db)
    }

    private func withDatabaseResult<Value>(defaultValue: Value, _ work: (OpaquePointer?) -> Value) -> Value {
        var db: OpaquePointer?
        guard sqlite3_open(databaseURL.path, &db) == SQLITE_OK else { return defaultValue }
        defer { sqlite3_close(db) }
        return work(db)
    }

    private func execute(_ sql: String, db: OpaquePointer?, bindings: [String?] = []) {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(statement) }
        for (index, binding) in bindings.enumerated() {
            bindText(binding, to: Int32(index + 1), statement: statement)
        }
        _ = sqlite3_step(statement)
    }

    private func bindText(_ value: String?, to index: Int32, statement: OpaquePointer?) {
        guard let value else {
            sqlite3_bind_null(statement, index)
            return
        }
        sqlite3_bind_text(statement, index, value, -1, SQLITE_TRANSIENT)
    }

    private func escapeLike(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
    }

}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
