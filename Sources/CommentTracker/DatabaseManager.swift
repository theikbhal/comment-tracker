import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

@MainActor
final class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: OpaquePointer?

    var databaseURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("CommentTracker", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("comments.sqlite")
    }

    private init() {
        if sqlite3_open(databaseURL.path, &db) == SQLITE_OK {
            migrate()
        } else {
            fatalError("Could not open database at \(databaseURL.path)")
        }
    }

    private func migrate() {
        let schema = """
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS comments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            platform TEXT NOT NULL,
            body TEXT,
            url TEXT,
            session_id INTEGER,
            created_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            started_at REAL NOT NULL,
            ended_at REAL,
            goal INTEGER NOT NULL
        );
        CREATE TABLE IF NOT EXISTS people (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            brief TEXT,
            description TEXT,
            stage TEXT NOT NULL DEFAULT 'holding',
            position INTEGER NOT NULL DEFAULT 0,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS people_links (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            person_id INTEGER NOT NULL,
            label TEXT,
            url TEXT NOT NULL,
            kind TEXT NOT NULL DEFAULT 'other'
        );
        CREATE TABLE IF NOT EXISTS people_comments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            person_id INTEGER NOT NULL,
            body TEXT NOT NULL,
            created_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS videos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            note TEXT,
            description TEXT,
            platform TEXT NOT NULL DEFAULT 'youtube',
            url TEXT,
            stage TEXT NOT NULL DEFAULT 'holding',
            position INTEGER NOT NULL DEFAULT 0,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS video_comments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            video_id INTEGER NOT NULL,
            body TEXT NOT NULL,
            created_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS thoughts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            note TEXT,
            list TEXT NOT NULL DEFAULT 'longterm',
            position INTEGER NOT NULL DEFAULT 0,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS wins (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            bookmarked INTEGER NOT NULL DEFAULT 0,
            created_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS fails (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            bookmarked INTEGER NOT NULL DEFAULT 0,
            created_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS interstitial_notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            created_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS bucks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'active',
            notes TEXT NOT NULL DEFAULT '',
            position INTEGER NOT NULL DEFAULT 0,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS focus (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            started_at REAL NOT NULL,
            ended_at REAL
        );
        CREATE TABLE IF NOT EXISTS parallel (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lane INTEGER NOT NULL DEFAULT 0,
            text TEXT NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            created_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS projects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'inProgress',
            start_note TEXT NOT NULL DEFAULT '',
            stop_note TEXT NOT NULL DEFAULT '',
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS deepwork_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            minutes INTEGER NOT NULL,
            started_at REAL NOT NULL,
            ended_at REAL NOT NULL,
            completed INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS schedule (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            day INTEGER NOT NULL,
            slot INTEGER NOT NULL,
            task TEXT NOT NULL,
            updated_at REAL NOT NULL,
            UNIQUE(day, slot)
        );
        CREATE TABLE IF NOT EXISTS holding (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            bookmarked INTEGER NOT NULL DEFAULT 0,
            done INTEGER NOT NULL DEFAULT 0,
            created_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS urgent (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            urgency INTEGER NOT NULL,
            text TEXT NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            position INTEGER NOT NULL,
            done INTEGER NOT NULL DEFAULT 0,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS mindmaps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS mindmap_nodes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            map_id INTEGER NOT NULL,
            parent_id INTEGER,
            text TEXT NOT NULL,
            color TEXT NOT NULL DEFAULT 'blue',
            x REAL NOT NULL DEFAULT 0,
            y REAL NOT NULL DEFAULT 0,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS blog_posts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            body TEXT NOT NULL DEFAULT '',
            status TEXT NOT NULL DEFAULT 'draft',
            tags TEXT NOT NULL DEFAULT '',
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL,
            published_at REAL
        );
        CREATE TABLE IF NOT EXISTS slack_channels (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color TEXT NOT NULL DEFAULT 'blue',
            created_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS slack_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            channel_id INTEGER NOT NULL,
            author TEXT NOT NULL,
            text TEXT NOT NULL,
            created_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS links (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            label TEXT,
            url TEXT NOT NULL,
            position INTEGER NOT NULL DEFAULT 0,
            created_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS wordcards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            slot INTEGER NOT NULL DEFAULT 0,
            word TEXT NOT NULL,
            group_name TEXT NOT NULL DEFAULT '',
            words TEXT NOT NULL DEFAULT '',
            link TEXT,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS pomodoro_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mode TEXT NOT NULL,
            started_at REAL NOT NULL,
            ended_at REAL
        );
        CREATE TABLE IF NOT EXISTS sprints (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            start_at REAL,
            end_at REAL,
            notes TEXT,
            done INTEGER NOT NULL DEFAULT 0,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS stories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sprint_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS story_tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            story_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            done INTEGER NOT NULL DEFAULT 0,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS trackers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            icon TEXT NOT NULL DEFAULT 'checkmark.circle',
            color TEXT NOT NULL DEFAULT 'blue',
            category TEXT NOT NULL DEFAULT 'Custom',
            is_counter INTEGER NOT NULL DEFAULT 0,
            target INTEGER NOT NULL DEFAULT 1,
            schedule_note TEXT,
            is_preset INTEGER NOT NULL DEFAULT 0,
            enabled INTEGER NOT NULL DEFAULT 1,
            sort_order INTEGER NOT NULL DEFAULT 0,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS tracker_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tracker_id INTEGER NOT NULL,
            day TEXT NOT NULL,
            count INTEGER NOT NULL DEFAULT 0,
            note TEXT,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL,
            UNIQUE(tracker_id, day)
        );
        """
        for statement in schema.split(separator: ";").map({ String($0).trimmingCharacters(in: .whitespacesAndNewlines) })
        where !statement.isEmpty {
            _ = execute(statement)
        }
        ensureColumn(table: "wordcards", column: "slot", definition: "INTEGER NOT NULL DEFAULT 0")
        _ = execute("UPDATE wordcards SET slot = id WHERE slot = 0")
    }

    private func ensureColumn(table: String, column: String, definition: String) {
        let columns = query("PRAGMA table_info(\(table))").compactMap { $0["name"] as? String }
        if !columns.contains(column) {
            _ = execute("ALTER TABLE \(table) ADD COLUMN \(column) \(definition)")
        }
    }

    @discardableResult
    func execute(_ sql: String, _ bind: [Any?] = []) -> Bool {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        bindParams(stmt, bind)
        return sqlite3_step(stmt) == SQLITE_DONE
    }

    func lastInsertID() -> Int {
        Int(sqlite3_last_insert_rowid(db))
    }

    func query(_ sql: String, _ bind: [Any?] = []) -> [[String: Any]] {
        var rows: [[String: Any]] = []
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        bindParams(stmt, bind)
        while sqlite3_step(stmt) == SQLITE_ROW {
            var row: [String: Any] = [:]
            for col in 0..<sqlite3_column_count(stmt) {
                let name = String(cString: sqlite3_column_name(stmt, col))
                switch sqlite3_column_type(stmt, col) {
                case SQLITE_INTEGER:
                    row[name] = Int(sqlite3_column_int64(stmt, col))
                case SQLITE_FLOAT:
                    row[name] = sqlite3_column_double(stmt, col)
                case SQLITE_TEXT:
                    row[name] = String(cString: sqlite3_column_text(stmt, col))
                default:
                    row[name] = NSNull()
                }
            }
            rows.append(row)
        }
        return rows
    }

    private func bindParams(_ stmt: OpaquePointer?, _ bind: [Any?]) {
        for (i, v) in bind.enumerated() {
            let idx = Int32(i + 1)
            switch v {
            case let s as String:
                sqlite3_bind_text(stmt, idx, s, -1, SQLITE_TRANSIENT)
            case let i as Int:
                sqlite3_bind_int64(stmt, idx, Int64(i))
            case let d as Double:
                sqlite3_bind_double(stmt, idx, d)
            case let b as Bool:
                sqlite3_bind_int(stmt, idx, b ? 1 : 0)
            case is NSNull, nil:
                sqlite3_bind_null(stmt, idx)
            default:
                sqlite3_bind_null(stmt, idx)
            }
        }
    }

    // MARK: - Backup & Restore

    func backup(to url: URL) -> Bool {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "VACUUM INTO ?", -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, url.path, -1, SQLITE_TRANSIENT)
        return sqlite3_step(stmt) == SQLITE_DONE
    }

    func restore(from url: URL) -> Bool {
        sqlite3_close(db)
        db = nil
        let safety = databaseURL.deletingPathExtension().appendingPathExtension("pre-restore.sqlite")
        try? FileManager.default.removeItem(at: safety)
        try? FileManager.default.copyItem(at: databaseURL, to: safety)
        try? FileManager.default.removeItem(at: databaseURL)
        do {
            try FileManager.default.copyItem(at: url, to: databaseURL)
        } catch {
            try? FileManager.default.copyItem(at: safety, to: databaseURL)
            open()
            return false
        }
        open()
        return true
    }

    private func open() {
        if sqlite3_open(databaseURL.path, &db) == SQLITE_OK {
            migrate()
        }
    }

    // MARK: - Settings

    var allSettings: [String: String] {
        var out: [String: String] = [:]
        for row in query("SELECT key, value FROM settings") {
            if let k = row["key"] as? String, let v = row["value"] as? String {
                out[k] = v
            }
        }
        return out
    }

    func setSetting(_ key: String, _ value: String) {
        _ = execute(
            "INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value",
            [key, value]
        )
    }
}
