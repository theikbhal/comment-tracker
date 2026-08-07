import Foundation
import SwiftUI

@MainActor
final class Store: ObservableObject {
    static let shared = Store()

    private let db = DatabaseManager.shared

    @Published var goal: Int = 313
    @Published var subGoal: Int = 30
    @Published var peopleGoal: Int = 313
    @Published var isOnboarded: Bool = false
    @Published var comments: [Comment] = []
    @Published var sessions: [Session] = []
    @Published var activeSession: Session?
    @Published var now = Date()

    @Published var people: [Person] = []
    @Published var peopleLinks: [PersonLink] = []
    @Published var peopleComments: [PersonComment] = []
    @Published var personToDetail: Person?

    @Published var videos: [Video] = []
    @Published var videoComments: [VideoComment] = []
    @Published var videoToDetail: Video?

    @Published var thoughts: [Thought] = []

    @Published var wins: [Win] = []

    @Published var trackers: [Tracker] = []
    @Published var trackerEntries: [TrackerEntry] = []
    @Published var trackerToDetail: Tracker?

    private var timer: Timer?

    init() {
        load()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.now = Date() }
        }
    }

    // MARK: - Loading

    func load() {
        let settings = db.allSettings
        if let g = settings["dailyGoal"].flatMap(Int.init), g > 0 {
            goal = g
        }
        if let s = settings["subGoal"].flatMap(Int.init), s > 0 {
            subGoal = s
        }
        if let p = settings["peopleGoal"].flatMap(Int.init), p > 0 {
            peopleGoal = p
        }
        isOnboarded = settings["onboarded"] == "true"
        seedPresetsIfNeeded()
        refresh()
    }

    func refresh() {
        comments = loadComments()
        sessions = loadSessions()
        activeSession = sessions.first { $0.isActive }
        people = loadPeople()
        peopleLinks = loadPersonLinks()
        peopleComments = loadPersonComments()
        videos = loadVideos()
        videoComments = loadVideoComments()
        thoughts = loadThoughts()
        wins = loadWins()
        trackers = loadTrackers()
        trackerEntries = loadTrackerEntries()
    }

    // MARK: - Onboarding

    func finishOnboarding() {
        db.setSetting("dailyGoal", "\(goal)")
        db.setSetting("subGoal", "\(subGoal)")
        db.setSetting("onboarded", "true")
        isOnboarded = true
    }

    func updateGoal(_ newGoal: Int) {
        goal = max(1, newGoal)
        db.setSetting("dailyGoal", "\(goal)")
    }

    func updateSubGoal(_ newSubGoal: Int) {
        subGoal = max(1, newSubGoal)
        db.setSetting("subGoal", "\(subGoal)")
    }

    func updatePeopleGoal(_ newGoal: Int) {
        peopleGoal = max(1, newGoal)
        db.setSetting("peopleGoal", "\(peopleGoal)")
    }

    // MARK: - Comments

    func addComment(platform: Platform, body: String?, url: String?) {
        let createdAt = Date().timeIntervalSince1970
        let sessionID = activeSession?.id
        let trimmedBody = body?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = url?.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = db.execute(
            "INSERT INTO comments (platform, body, url, session_id, created_at) VALUES (?, ?, ?, ?, ?)",
            [platform.rawValue, trimmedBody, trimmedURL, sessionID, createdAt]
        )
        refresh()
    }

    // MARK: - Sessions

    func toggleSession() {
        if activeSession != nil {
            endSession()
        } else {
            startSession()
        }
    }

    func startSession() {
        let now = Date().timeIntervalSince1970
        _ = db.execute("INSERT INTO sessions (started_at, goal) VALUES (?, ?)", [now, goal])
        refresh()
    }

    func endSession() {
        guard let s = activeSession else { return }
        _ = db.execute("UPDATE sessions SET ended_at = ? WHERE id = ?", [Date().timeIntervalSince1970, s.id])
        refresh()
    }

    // MARK: - People

    var totalPeople: Int { people.count }

    func peopleForStage(_ stage: PersonStage) -> [Person] {
        people
            .filter { $0.stage == stage }
            .sorted { $0.position < $1.position }
    }

    func person(_ p: Person, matches query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        if p.name.lowercased().contains(q) { return true }
        if p.brief.lowercased().contains(q) { return true }
        if p.description.lowercased().contains(q) { return true }
        for link in peopleLinks where link.personId == p.id {
            if link.label.lowercased().contains(q) || link.url.lowercased().contains(q) {
                return true
            }
        }
        for comment in peopleComments where comment.personId == p.id {
            if comment.body.lowercased().contains(q) {
                return true
            }
        }
        return false
    }

    func personByID(_ id: Int) -> Person? {
        people.first { $0.id == id }
    }

    func links(for personID: Int) -> [PersonLink] {
        peopleLinks.filter { $0.personId == personID }
    }

    func comments(for personID: Int) -> [PersonComment] {
        peopleComments
            .filter { $0.personId == personID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func addPerson(name: String, brief: String = "", stage: PersonStage = .holding) {
        let now = Date().timeIntervalSince1970
        let position = peopleForStage(stage).count
        _ = db.execute(
            "INSERT INTO people (name, brief, description, stage, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            [name, brief, "", stage.rawValue, position, now, now]
        )
        refresh()
    }

    func updatePerson(id: Int, name: String? = nil, brief: String? = nil, description: String? = nil, stage: PersonStage? = nil) {
        guard let p = personByID(id) else { return }
        let newStage = stage ?? p.stage
        _ = db.execute(
            "UPDATE people SET name = ?, brief = ?, description = ?, stage = ?, updated_at = ? WHERE id = ?",
            [name ?? p.name, brief ?? p.brief, description ?? p.description, newStage.rawValue, Date().timeIntervalSince1970, id]
        )
        if let stage, stage != p.stage {
            reindexColumn(p.stage)
            reindexColumn(stage)
        }
        refresh()
    }

    func deletePerson(_ id: Int) {
        _ = db.execute("DELETE FROM people_links WHERE person_id = ?", [id])
        _ = db.execute("DELETE FROM people_comments WHERE person_id = ?", [id])
        _ = db.execute("DELETE FROM people WHERE id = ?", [id])
        refresh()
    }

    func movePerson(_ id: Int, to stage: PersonStage, at index: Int) {
        guard let p = personByID(id) else { return }
        let fromStage = p.stage
        var target = peopleForStage(stage)
        target.removeAll { $0.id == id }
        let clamped = max(0, min(index, target.count))
        target.insert(p, at: clamped)
        writeOrder(target, stage: stage)
        if fromStage != stage {
            writeOrder(peopleForStage(fromStage).filter { $0.id != id }, stage: fromStage)
        }
        refresh()
    }

    func reindexColumn(_ stage: PersonStage) {
        writeOrder(peopleForStage(stage), stage: stage)
    }

    private func writeOrder(_ ordered: [Person], stage: PersonStage) {
        for (i, person) in ordered.enumerated() {
            _ = db.execute("UPDATE people SET position = ?, updated_at = ? WHERE id = ?", [i, Date().timeIntervalSince1970, person.id])
        }
    }

    func addPersonLink(personID: Int, label: String, url: String, kind: PersonLinkKind) {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO people_links (person_id, label, url, kind) VALUES (?, ?, ?, ?)",
            [personID, label, trimmed, kind.rawValue]
        )
        refresh()
    }

    func deletePersonLink(_ id: Int) {
        _ = db.execute("DELETE FROM people_links WHERE id = ?", [id])
        refresh()
    }

    func addPersonComment(personID: Int, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO people_comments (person_id, body, created_at) VALUES (?, ?, ?)",
            [personID, trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    // MARK: - Videos

    var totalVideos: Int { videos.count }

    func videosForStage(_ stage: VideoStage) -> [Video] {
        videos
            .filter { $0.stage == stage }
            .sorted { $0.position < $1.position }
    }

    func videoByID(_ id: Int) -> Video? {
        videos.first { $0.id == id }
    }

    func videoComments(for videoID: Int) -> [VideoComment] {
        videoComments
            .filter { $0.videoId == videoID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func video(_ v: Video, matches query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        if v.title.lowercased().contains(q) { return true }
        if v.note.lowercased().contains(q) { return true }
        if v.description.lowercased().contains(q) { return true }
        if v.url.lowercased().contains(q) { return true }
        for comment in videoComments where comment.videoId == v.id {
            if comment.body.lowercased().contains(q) { return true }
        }
        return false
    }

    func addVideo(title: String, url: String, platform: VideoPlatform, stage: VideoStage = .holding) {
        let now = Date().timeIntervalSince1970
        let position = videosForStage(stage).count
        _ = db.execute(
            "INSERT INTO videos (title, note, description, platform, url, stage, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            [title, "", "", platform.rawValue, url, stage.rawValue, position, now, now]
        )
        refresh()
    }

    func updateVideo(id: Int, title: String? = nil, note: String? = nil, description: String? = nil, url: String? = nil, platform: VideoPlatform? = nil, stage: VideoStage? = nil) {
        guard let v = videoByID(id) else { return }
        let newStage = stage ?? v.stage
        _ = db.execute(
            "UPDATE videos SET title = ?, note = ?, description = ?, url = ?, platform = ?, stage = ?, updated_at = ? WHERE id = ?",
            [title ?? v.title, note ?? v.note, description ?? v.description, url ?? v.url, (platform ?? v.platform).rawValue, newStage.rawValue, Date().timeIntervalSince1970, id]
        )
        if let stage, stage != v.stage {
            reindexVideoColumn(v.stage)
            reindexVideoColumn(stage)
        }
        refresh()
    }

    func deleteVideo(_ id: Int) {
        _ = db.execute("DELETE FROM video_comments WHERE video_id = ?", [id])
        _ = db.execute("DELETE FROM videos WHERE id = ?", [id])
        refresh()
    }

    func moveVideo(_ id: Int, to stage: VideoStage, at index: Int) {
        guard let v = videoByID(id) else { return }
        let fromStage = v.stage
        var target = videosForStage(stage)
        target.removeAll { $0.id == id }
        let clamped = max(0, min(index, target.count))
        target.insert(v, at: clamped)
        writeVideoOrder(target, stage: stage)
        if fromStage != stage {
            writeVideoOrder(videosForStage(fromStage).filter { $0.id != id }, stage: fromStage)
        }
        refresh()
    }

    func reindexVideoColumn(_ stage: VideoStage) {
        writeVideoOrder(videosForStage(stage), stage: stage)
    }

    private func writeVideoOrder(_ ordered: [Video], stage: VideoStage) {
        for (i, video) in ordered.enumerated() {
            _ = db.execute("UPDATE videos SET position = ?, updated_at = ? WHERE id = ?", [i, Date().timeIntervalSince1970, video.id])
        }
    }

    func addVideoComment(videoID: Int, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO video_comments (video_id, body, created_at) VALUES (?, ?, ?)",
            [videoID, trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    // MARK: - Thoughts

    func thoughtsForList(_ list: ThoughtList) -> [Thought] {
        thoughts
            .filter { $0.list == list }
            .sorted { $0.position < $1.position }
    }

    func thoughtByID(_ id: Int) -> Thought? {
        thoughts.first { $0.id == id }
    }

    func thought(_ t: Thought, matches query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        if t.title.lowercased().contains(q) { return true }
        if t.note.lowercased().contains(q) { return true }
        return false
    }

    func addThought(title: String, note: String = "", list: ThoughtList = .longTerm) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        let position = thoughtsForList(list).count
        _ = db.execute(
            "INSERT INTO thoughts (title, note, list, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            [trimmed, note, list.rawValue, position, now, now]
        )
        refresh()
    }

    func addThoughts(_ titles: [String], list: ThoughtList) {
        let parsed = titles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !parsed.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        var position = thoughtsForList(list).count
        for title in parsed {
            _ = db.execute(
                "INSERT INTO thoughts (title, note, list, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
                [title, "", list.rawValue, position, now, now]
            )
            position += 1
        }
        refresh()
    }

    func updateThought(id: Int, title: String? = nil, note: String? = nil, list: ThoughtList? = nil) {
        guard let t = thoughtByID(id) else { return }
        let newList = list ?? t.list
        _ = db.execute(
            "UPDATE thoughts SET title = ?, note = ?, list = ?, updated_at = ? WHERE id = ?",
            [title ?? t.title, note ?? t.note, newList.rawValue, Date().timeIntervalSince1970, id]
        )
        if let list, list != t.list {
            reindexThoughtList(t.list)
            reindexThoughtList(list)
        }
        refresh()
    }

    func deleteThought(_ id: Int) {
        _ = db.execute("DELETE FROM thoughts WHERE id = ?", [id])
        refresh()
    }

    func moveThought(_ id: Int, to list: ThoughtList, at index: Int) {
        guard let t = thoughtByID(id) else { return }
        let fromList = t.list
        var target = thoughtsForList(list)
        target.removeAll { $0.id == id }
        let clamped = max(0, min(index, target.count))
        target.insert(t, at: clamped)
        writeThoughtOrder(target, list: list)
        if fromList != list {
            writeThoughtOrder(thoughtsForList(fromList).filter { $0.id != id }, list: fromList)
        }
        refresh()
    }

    func reindexThoughtList(_ list: ThoughtList) {
        writeThoughtOrder(thoughtsForList(list), list: list)
    }

    private func writeThoughtOrder(_ ordered: [Thought], list: ThoughtList) {
        for (i, thought) in ordered.enumerated() {
            _ = db.execute("UPDATE thoughts SET position = ?, updated_at = ? WHERE id = ?", [i, Date().timeIntervalSince1970, thought.id])
        }
    }

    func randomActiveThought() -> Thought? {
        thoughts.isEmpty ? nil : thoughts.randomElement()
    }

    // MARK: - Wins

    func win(_ w: Win, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return w.text.lowercased().contains(query.lowercased())
    }

    func addWin(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO wins (text, bookmarked, created_at) VALUES (?, 0, ?)",
            [trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteWin(_ id: Int) {
        _ = db.execute("DELETE FROM wins WHERE id = ?", [id])
        refresh()
    }

    func toggleWinBookmark(_ id: Int) -> Bool {
        guard let w = wins.first(where: { $0.id == id }) else { return false }
        let newValue = w.bookmarked ? 0 : 1
        _ = db.execute("UPDATE wins SET bookmarked = ? WHERE id = ?", [newValue, id])
        refresh()
        return newValue == 1
    }

    // MARK: - Backup & Restore

    @discardableResult
    func backup(to url: URL) -> Bool {
        db.backup(to: url)
    }

    @discardableResult
    func restore(from url: URL) -> Bool {
        let ok = db.restore(from: url)
        if ok { load() }
        return ok
    }

    // MARK: - Trackers

    var enabledTrackers: [Tracker] {
        trackers.filter { $0.enabled }
    }

    func trackerByID(_ id: Int) -> Tracker? {
        trackers.first { $0.id == id }
    }

    var trackerCategories: [String] {
        var seen: [String] = []
        let order = ["Namaz", "Quran", "Zikr", "Dua", "Fasting", "Masjid", "Family", "Parents", "Relatives", "Parenting", "Friends", "Health", "Business", "Custom"]
        for cat in order where enabledTrackers.contains(where: { $0.category == cat }) {
            seen.append(cat)
        }
        for t in enabledTrackers where !seen.contains(t.category) {
            seen.append(t.category)
        }
        return seen
    }

    func trackersForCategory(_ category: String) -> [Tracker] {
        enabledTrackers
            .filter { $0.category == category }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func tracker(_ t: Tracker, matches query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        return t.name.lowercased().contains(q)
            || t.category.lowercased().contains(q)
            || t.scheduleNote.lowercased().contains(q)
    }

    // MARK: Entries

    func entry(for trackerID: Int, on day: String) -> TrackerEntry? {
        trackerEntries.first { $0.trackerId == trackerID && $0.day == day }
    }

    func count(for trackerID: Int, on day: String) -> Int {
        entry(for: trackerID, on: day)?.count ?? 0
    }

    func note(for trackerID: Int, on day: String) -> String {
        entry(for: trackerID, on: day)?.note ?? ""
    }

    func isDone(trackerID: Int, on day: String) -> Bool {
        count(for: trackerID, on: day) > 0
    }

    func toggle(_ trackerID: Int, on day: String) {
        let current = count(for: trackerID, on: day)
        upsertEntry(trackerID: trackerID, day: day, count: current > 0 ? 0 : 1, note: nil)
    }

    func setCount(_ trackerID: Int, on day: String, _ value: Int) {
        upsertEntry(trackerID: trackerID, day: day, count: max(0, value), note: nil)
    }

    func setNote(_ trackerID: Int, on day: String, _ note: String) {
        upsertEntry(trackerID: trackerID, day: day, count: nil, note: note)
    }

    private func upsertEntry(trackerID: Int, day: String, count: Int?, note: String?) {
        let existing = entry(for: trackerID, on: day)
        let c = count ?? existing?.count ?? 0
        let n = note ?? existing?.note ?? ""
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO tracker_entries (tracker_id, day, count, note, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT(tracker_id, day) DO UPDATE SET count = excluded.count, note = excluded.note, updated_at = excluded.updated_at",
            [trackerID, day, c, n, now, now]
        )
        refresh()
    }

    func entries(for trackerID: Int, inMonthOf date: Date) -> [TrackerEntry] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        guard let monthStart = cal.date(from: comps),
              let monthEnd = cal.date(byAdding: DateComponents(month: 1), to: monthStart) else { return [] }
        let start = dayString(monthStart)
        let end = dayString(monthEnd)
        return trackerEntries.filter { $0.trackerId == trackerID && $0.day >= start && $0.day < end }
    }

    func daysDone(for trackerID: Int, inMonthOf date: Date) -> Set<String> {
        Set(entries(for: trackerID, inMonthOf: date).filter { $0.count > 0 }.map { $0.day })
    }

    func monthDoneCount(for trackerID: Int, inMonthOf date: Date) -> Int {
        daysDone(for: trackerID, inMonthOf: date).count
    }

    func streak(for trackerID: Int) -> Int {
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        let today = day
        if !isDone(trackerID: trackerID, on: dayString(today)) {
            guard let y = cal.date(byAdding: .day, value: -1, to: today),
                  isDone(trackerID: trackerID, on: dayString(y)) else { return 0 }
            day = y
        }
        var count = 0
        while isDone(trackerID: trackerID, on: dayString(day)) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    // MARK: CRUD

    func addTracker(name: String, category: String, icon: String, colorName: String, isCounter: Bool, target: Int, scheduleNote: String) {
        let now = Date().timeIntervalSince1970
        let maxOrder = (trackers.filter { $0.category == category }.map { $0.sortOrder }.max() ?? -1) + 1
        _ = db.execute(
            "INSERT INTO trackers (name, icon, color, category, is_counter, target, schedule_note, is_preset, enabled, sort_order, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, 0, 1, ?, ?, ?)",
            [name, icon, colorName, category, isCounter ? 1 : 0, max(1, target), scheduleNote, maxOrder, now, now]
        )
        refresh()
    }

    func updateTracker(id: Int, enabled: Bool? = nil, target: Int? = nil) {
        guard let t = trackerByID(id) else { return }
        _ = db.execute(
            "UPDATE trackers SET enabled = ?, target = ?, updated_at = ? WHERE id = ?",
            [enabled ?? t.enabled ? 1 : 0, target ?? t.target, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func deleteTracker(_ id: Int) {
        _ = db.execute("DELETE FROM tracker_entries WHERE tracker_id = ?", [id])
        _ = db.execute("DELETE FROM trackers WHERE id = ?", [id])
        refresh()
    }

    func seedPresetsIfNeeded() {
        let settings = db.allSettings
        guard settings["presetsSeeded"] != "true" else { return }
        insertPresets()
        db.setSetting("presetsSeeded", "true")
        refresh()
    }

    func reseedMissingPresets() {
        let existingNames = Set(trackers.map { $0.name })
        let missing = TrackerPreset.all.filter { !existingNames.contains($0.name) }
        guard !missing.isEmpty else { return }
        insertPresets(missing)
        refresh()
    }

    private func insertPresets(_ presets: [TrackerPreset] = TrackerPreset.all) {
        let now = Date().timeIntervalSince1970
        for (i, p) in presets.enumerated() {
            _ = db.execute(
                "INSERT INTO trackers (name, icon, color, category, is_counter, target, schedule_note, is_preset, enabled, sort_order, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, 1, 1, ?, ?, ?)",
                [p.name, p.icon, p.color, p.category, p.isCounter ? 1 : 0, p.target, p.scheduleNote, i, now, now]
            )
        }
    }

    // MARK: - Derived data

    var todayStart: Date {
        Calendar.current.startOfDay(for: Date())
    }

    var todayComments: [Comment] {
        let start = todayStart
        return comments.filter { $0.createdAt >= start }
    }

    var todayCount: Int { todayComments.count }

    var todayByPlatform: [Platform: Int] {
        var out: [Platform: Int] = [:]
        for c in todayComments {
            out[c.platform, default: 0] += 1
        }
        return out
    }

    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1, Double(todayCount) / Double(goal))
    }

    var subGoalProgress: Double {
        guard subGoal > 0 else { return 0 }
        return min(1, Double(todayCount) / Double(subGoal))
    }

    var remainingSubGoal: Int {
        max(0, subGoal - todayCount)
    }

    var remainingCount: Int {
        max(0, goal - todayCount)
    }

    var currentMilestone: Milestone? {
        Milestone.reached(by: progress)
    }

    var nextMilestone: Milestone? {
        Milestone.next(after: progress)
    }

    var minutesElapsedToday: Double {
        max(1, Date().timeIntervalSince(todayStart) / 60)
    }

    var pacePerHour: Double {
        let hours = minutesElapsedToday / 60
        return Double(todayCount) / hours
    }

    var estimatedFinish: TimeInterval? {
        guard pacePerHour > 0, remainingCount > 0 else { return nil }
        return TimeInterval(remainingCount) / pacePerHour * 3600
    }

    var weeklyCounts: [DailyCount] {
        var counts: [Date: Int] = [:]
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -6, to: todayStart)!
        for c in comments {
            let day = cal.startOfDay(for: c.createdAt)
            if day >= start {
                counts[day, default: 0] += 1
            }
        }
        return (0...6).compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: offset, to: start) else { return nil }
            return DailyCount(date: day, count: counts[day] ?? 0)
        }
    }

    var totalCount: Int { comments.count }

    var totalSessions: Int { sessions.count }

    var totalTime: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    // MARK: - Private loading

    private func loadComments() -> [Comment] {
        db.query("SELECT * FROM comments ORDER BY created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let pRaw = row["platform"] as? String,
                let p = Platform(rawValue: pRaw),
                let ts = row["created_at"] as? Double
            else { return nil }
            return Comment(
                id: id,
                platform: p,
                body: row["body"] as? String,
                url: row["url"] as? String,
                createdAt: Date(timeIntervalSince1970: ts),
                sessionId: row["session_id"] as? Int
            )
        }
    }

    private func loadSessions() -> [Session] {
        let rows = db.query("""
        SELECT s.*, (SELECT COUNT(*) FROM comments c WHERE c.session_id = s.id) AS comments_added
        FROM sessions s ORDER BY s.started_at DESC
        """)
        return rows.compactMap { row in
            guard
                let id = row["id"] as? Int,
                let start = row["started_at"] as? Double
            else { return nil }
            return Session(
                id: id,
                startedAt: Date(timeIntervalSince1970: start),
                endedAt: (row["ended_at"] as? Double).map { Date(timeIntervalSince1970: $0) },
                goal: row["goal"] as? Int ?? 0,
                commentsAdded: row["comments_added"] as? Int ?? 0
            )
        }
    }

    private func loadPeople() -> [Person] {
        db.query("SELECT * FROM people ORDER BY position ASC, created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let name = row["name"] as? String,
                let stageRaw = row["stage"] as? String,
                let stage = PersonStage(rawValue: stageRaw),
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double
            else { return nil }
            return Person(
                id: id,
                name: name,
                brief: row["brief"] as? String ?? "",
                description: row["description"] as? String ?? "",
                stage: stage,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: row["updated_at"] as? Double ?? created)
            )
        }
    }

    private func loadPersonLinks() -> [PersonLink] {
        db.query("SELECT * FROM people_links").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let personID = row["person_id"] as? Int,
                let url = row["url"] as? String,
                let kindRaw = row["kind"] as? String,
                let kind = PersonLinkKind(rawValue: kindRaw)
            else { return nil }
            return PersonLink(
                id: id,
                personId: personID,
                label: row["label"] as? String ?? "",
                url: url,
                kind: kind
            )
        }
    }

    private func loadPersonComments() -> [PersonComment] {
        db.query("SELECT * FROM people_comments ORDER BY created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let personID = row["person_id"] as? Int,
                let body = row["body"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return PersonComment(
                id: id,
                personId: personID,
                body: body,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func loadWins() -> [Win] {
        db.query("SELECT * FROM wins ORDER BY created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let text = row["text"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return Win(
                id: id,
                text: text,
                bookmarked: (row["bookmarked"] as? Int ?? 0) == 1,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func loadThoughts() -> [Thought] {
        db.query("SELECT * FROM thoughts ORDER BY position ASC, created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let listRaw = row["list"] as? String,
                let list = ThoughtList(rawValue: listRaw),
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double
            else { return nil }
            return Thought(
                id: id,
                title: title,
                note: row["note"] as? String ?? "",
                list: list,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: row["updated_at"] as? Double ?? created)
            )
        }
    }

    private func loadVideos() -> [Video] {
        db.query("SELECT * FROM videos ORDER BY position ASC, created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let stageRaw = row["stage"] as? String,
                let stage = VideoStage(rawValue: stageRaw),
                let platformRaw = row["platform"] as? String,
                let platform = VideoPlatform(rawValue: platformRaw),
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double
            else { return nil }
            return Video(
                id: id,
                title: title,
                note: row["note"] as? String ?? "",
                description: row["description"] as? String ?? "",
                url: row["url"] as? String ?? "",
                platform: platform,
                stage: stage,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: row["updated_at"] as? Double ?? created)
            )
        }
    }

    private func loadVideoComments() -> [VideoComment] {
        db.query("SELECT * FROM video_comments ORDER BY created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let videoID = row["video_id"] as? Int,
                let body = row["body"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return VideoComment(
                id: id,
                videoId: videoID,
                body: body,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func loadTrackers() -> [Tracker] {
        db.query("SELECT * FROM trackers ORDER BY sort_order ASC, id ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let name = row["name"] as? String,
                let category = row["category"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return Tracker(
                id: id,
                name: name,
                icon: row["icon"] as? String ?? "checkmark.circle",
                colorName: row["color"] as? String ?? "blue",
                category: category,
                isCounter: (row["is_counter"] as? Int ?? 0) == 1,
                target: row["target"] as? Int ?? 1,
                scheduleNote: row["schedule_note"] as? String ?? "",
                isPreset: (row["is_preset"] as? Int ?? 0) == 1,
                enabled: (row["enabled"] as? Int ?? 1) == 1,
                sortOrder: row["sort_order"] as? Int ?? 0,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: row["updated_at"] as? Double ?? created)
            )
        }
    }

    private func loadTrackerEntries() -> [TrackerEntry] {
        db.query("SELECT * FROM tracker_entries ORDER BY day ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let trackerID = row["tracker_id"] as? Int,
                let day = row["day"] as? String
            else { return nil }
            return TrackerEntry(
                id: id,
                trackerId: trackerID,
                day: day,
                count: row["count"] as? Int ?? 0,
                note: row["note"] as? String ?? ""
            )
        }
    }
}

struct DailyCount: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}
