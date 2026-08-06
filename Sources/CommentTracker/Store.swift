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
        refresh()
    }

    func refresh() {
        comments = loadComments()
        sessions = loadSessions()
        activeSession = sessions.first { $0.isActive }
        people = loadPeople()
        peopleLinks = loadPersonLinks()
        peopleComments = loadPersonComments()
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
}

struct DailyCount: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}
