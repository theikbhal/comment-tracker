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
    @Published var fails: [Fail] = []
    @Published var interNotes: [InterNote] = []
    @Published var bucks: [Buck] = []
    @Published var focusSessions: [Focus] = []
    @Published var parallel: [ParallelItem] = []
    @Published var projects: [Project] = []
    @Published var deepWork: [DeepWorkSession] = []
    @Published var schedule: [ScheduleEntry] = []
    @Published var holding: [HoldingItem] = []
    @Published var urgent: [UrgentItem] = []
    @Published var mindMaps: [MindMap] = []
    @Published var mindMapNodes: [MindMapNode] = []
    @Published var blogPosts: [BlogPost] = []
    @Published var slackChannels: [SlackChannel] = []
    @Published var slackMessages: [SlackMessage] = []
    @Published var calendarEvents: [CalendarEvent] = []

    @Published var links: [LinkItem] = []
    @Published var cards: [WordCard] = []
    @Published var pomodoros: [PomodoroSession] = []
    @Published var sprints: [Sprint] = []
    @Published var stories: [Story] = []
    @Published var storyTasks: [StoryTask] = []
    @Published var sprintToDetail: Sprint?

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
        seedSlackIfNeeded()
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
        fails = loadFails()
        interNotes = loadInterNotes()
        bucks = loadBucks()
        focusSessions = loadFocus()
        parallel = loadParallel()
        projects = loadProjects()
        deepWork = loadDeepWork()
        schedule = loadSchedule()
        holding = loadHolding()
        urgent = loadUrgent()
        mindMaps = loadMindMaps()
        mindMapNodes = loadMindMapNodes()
        blogPosts = loadBlogPosts()
        slackChannels = loadSlackChannels()
        slackMessages = loadSlackMessages()
        calendarEvents = loadCalendarEvents()
        links = loadLinks()
        cards = loadCards()
        pomodoros = loadPomodoros()
        sprints = loadSprints()
        stories = loadStories()
        storyTasks = loadStoryTasks()
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

    // MARK: - Fails

    func fail(_ f: Fail, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return f.text.lowercased().contains(query.lowercased())
    }

    func addFail(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO fails (text, bookmarked, created_at) VALUES (?, 0, ?)",
            [trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteFail(_ id: Int) {
        _ = db.execute("DELETE FROM fails WHERE id = ?", [id])
        refresh()
    }

    func toggleFailBookmark(_ id: Int) -> Bool {
        guard let f = fails.first(where: { $0.id == id }) else { return false }
        let newValue = f.bookmarked ? 0 : 1
        _ = db.execute("UPDATE fails SET bookmarked = ? WHERE id = ?", [newValue, id])
        refresh()
        return newValue == 1
    }

    // MARK: - Interstitial Notes

    func interNote(_ n: InterNote, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return n.text.lowercased().contains(query.lowercased())
    }

    func addInterNote(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO interstitial_notes (text, created_at) VALUES (?, ?)",
            [trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteInterNote(_ id: Int) {
        _ = db.execute("DELETE FROM interstitial_notes WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Buck Track

    func buckActiveCount(_ q: String) -> Int {
        fetchBucksFiltered(q).filter { $0.status == .active }.count
    }

    func buck(_ b: Buck, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return b.title.lowercased().contains(q) || b.notes.lowercased().contains(q)
    }

    func addBuck(title: String, notes: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let next = (bucks.map(\.position).max() ?? 0) + 1
        _ = db.execute(
            "INSERT INTO bucks (title, status, notes, position, created_at, updated_at) VALUES (?, 'active', ?, ?, ?, ?)",
            [trimmed, notes, next, Date().timeIntervalSince1970, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func setBuckStatus(_ id: Int, _ status: BuckStatus) {
        _ = db.execute(
            "UPDATE bucks SET status = ?, updated_at = ? WHERE id = ?",
            [status.rawValue, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func updateBuckNote(_ id: Int, notes: String) {
        _ = db.execute(
            "UPDATE bucks SET notes = ?, updated_at = ? WHERE id = ?",
            [notes, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func deleteBuck(_ id: Int) {
        _ = db.execute("DELETE FROM bucks WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Focus Tracker

    var currentFocus: Focus? {
        focusSessions.first { $0.isActive }
    }

    func focus(_ f: Focus, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return f.text.lowercased().contains(q) || f.note.lowercased().contains(q)
    }

    func startFocus(text: String, note: String = "") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, currentFocus == nil else { return }
        _ = db.execute(
            "INSERT INTO focus (text, note, started_at, ended_at) VALUES (?, ?, ?, NULL)",
            [trimmed, note, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func endFocus() {
        guard let f = currentFocus else { return }
        _ = db.execute("UPDATE focus SET ended_at = ? WHERE id = ?", [Date().timeIntervalSince1970, f.id])
        refresh()
    }

    func updateFocusNote(_ id: Int, note: String) {
        _ = db.execute("UPDATE focus SET note = ? WHERE id = ?", [note, id])
        refresh()
    }

    func deleteFocus(_ id: Int) {
        _ = db.execute("DELETE FROM focus WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Parallel

    func parallelItem(_ p: ParallelItem, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return p.text.lowercased().contains(q) || p.note.lowercased().contains(q)
    }

    func addParallelItem(lane: Int, text: String, note: String = "") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO parallel (lane, text, note, created_at) VALUES (?, ?, ?, ?)",
            [lane, trimmed, note, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func moveParallelItem(_ id: Int, to lane: Int) {
        _ = db.execute("UPDATE parallel SET lane = ? WHERE id = ?", [lane, id])
        refresh()
    }

    func updateParallelNote(_ id: Int, note: String) {
        _ = db.execute("UPDATE parallel SET note = ? WHERE id = ?", [note, id])
        refresh()
    }

    func deleteParallelItem(_ id: Int) {
        _ = db.execute("DELETE FROM parallel WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Project Tracker

    func project(_ p: Project, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return p.name.lowercased().contains(q) || p.startNote.lowercased().contains(q) || p.stopNote.lowercased().contains(q)
    }

    func addProject(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO projects (name, status, start_note, stop_note, created_at, updated_at) VALUES (?, 'inProgress', '', '', ?, ?)",
            [trimmed, Date().timeIntervalSince1970, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func startProject(_ id: Int) {
        let now = Date().timeIntervalSince1970
        _ = db.execute("UPDATE projects SET status = 'inProgress', updated_at = ? WHERE id != ? AND status = 'working'", [now, id])
        _ = db.execute("UPDATE projects SET status = 'working', updated_at = ? WHERE id = ?", [now, id])
        refresh()
    }

    func stopProject(_ id: Int) {
        _ = db.execute(
            "UPDATE projects SET status = 'inProgress', updated_at = ? WHERE id = ?",
            [Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func setProjectStatus(_ id: Int, _ status: ProjectStatus) {
        _ = db.execute(
            "UPDATE projects SET status = ?, updated_at = ? WHERE id = ?",
            [status.rawValue, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func updateProjectNotes(_ id: Int, startNote: String, stopNote: String) {
        _ = db.execute(
            "UPDATE projects SET start_note = ?, stop_note = ?, updated_at = ? WHERE id = ?",
            [startNote, stopNote, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func deleteProject(_ id: Int) {
        _ = db.execute("DELETE FROM projects WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Deep Work

    func deepWork(_ s: DeepWorkSession, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return query.lowercased().contains("deep") || query.lowercased().contains("work") || String(s.minutes).contains(query.lowercased())
    }

    var deepWorkMinutesToday: Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        return deepWork.filter { $0.startedAt >= start }.reduce(0) { $0 + $1.minutes }
    }

    func completeDeepWork(minutes: Int) {
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO deepwork_sessions (minutes, started_at, ended_at, completed) VALUES (?, ?, ?, 1)",
            [minutes, now - Double(minutes) * 60, now]
        )
        refresh()
        addWin(text: "Completed a \(minutes)-minute deep work block")
    }

    func deleteDeepWork(_ id: Int) {
        _ = db.execute("DELETE FROM deepwork_sessions WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Schedule

    func scheduleEntry(day: Int, slot: Int) -> ScheduleEntry? {
        schedule.first { $0.day == day && $0.slot == slot }
    }

    func setScheduleTask(day: Int, slot: Int, task: String) {
        let trimmed = task.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date().timeIntervalSince1970
        if trimmed.isEmpty {
            _ = db.execute("DELETE FROM schedule WHERE day = ? AND slot = ?", [day, slot])
        } else if scheduleEntry(day: day, slot: slot) != nil {
            _ = db.execute("UPDATE schedule SET task = ?, updated_at = ? WHERE day = ? AND slot = ?", [trimmed, now, day, slot])
        } else {
            _ = db.execute("INSERT INTO schedule (day, slot, task, updated_at) VALUES (?, ?, ?, ?)", [day, slot, trimmed, now])
        }
        refresh()
    }

    func clearScheduleSlot(day: Int, slot: Int) {
        _ = db.execute("DELETE FROM schedule WHERE day = ? AND slot = ?", [day, slot])
        refresh()
    }

    func schedule(_ e: ScheduleEntry, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return e.task.lowercased().contains(query.lowercased())
    }

    // MARK: - Holding Hand

    func holdingItem(_ h: HoldingItem, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return h.text.lowercased().contains(query.lowercased())
    }

    func addHolding(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO holding (text, bookmarked, done, created_at) VALUES (?, 0, 0, ?)",
            [trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteHolding(_ id: Int) {
        _ = db.execute("DELETE FROM holding WHERE id = ?", [id])
        refresh()
    }

    func toggleHoldingBookmark(_ id: Int) -> Bool {
        guard let h = holding.first(where: { $0.id == id }) else { return false }
        let newValue = h.bookmarked ? 0 : 1
        _ = db.execute("UPDATE holding SET bookmarked = ? WHERE id = ?", [newValue, id])
        refresh()
        return newValue == 1
    }

    func toggleHoldingDone(_ id: Int) -> Bool {
        guard let h = holding.first(where: { $0.id == id }) else { return false }
        let newValue = h.done ? 0 : 1
        _ = db.execute("UPDATE holding SET done = ? WHERE id = ?", [newValue, id])
        refresh()
        return newValue == 1
    }

    // MARK: - Urgent

    func urgentItem(_ u: UrgentItem, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return u.text.lowercased().contains(q) || u.note.lowercased().contains(q)
    }

    func urgentItems(for urgency: Urgency) -> [UrgentItem] {
        urgent
            .filter { $0.urgency == urgency }
            .sorted { $0.position < $1.position }
    }

    func addUrgent(text: String, urgency: Urgency, note: String = "") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        let position = urgentItems(for: urgency).count
        _ = db.execute(
            "INSERT INTO urgent (urgency, text, note, position, done, created_at, updated_at) VALUES (?, ?, ?, ?, 0, ?, ?)",
            [urgency.rawValue, trimmed, note, position, now, now]
        )
        refresh()
    }

    func moveUrgent(_ id: Int, to urgency: Urgency, at index: Int) {
        guard let item = urgent.first(where: { $0.id == id }) else { return }
        let from = item.urgency
        var target = urgentItems(for: urgency)
        target.removeAll { $0.id == id }
        let clamped = max(0, min(index, target.count))
        target.insert(item, at: clamped)
        writeUrgentOrder(target, urgency: urgency)
        if from != urgency {
            writeUrgentOrder(urgentItems(for: from).filter { $0.id != id }, urgency: from)
        }
        refresh()
    }

    func updateUrgent(id: Int, text: String? = nil, note: String? = nil, urgency: Urgency? = nil) {
        guard let item = urgent.first(where: { $0.id == id }) else { return }
        let newUrgency = urgency ?? item.urgency
        _ = db.execute(
            "UPDATE urgent SET text = ?, note = ?, urgency = ?, updated_at = ? WHERE id = ?",
            [text ?? item.text, note ?? item.note, newUrgency.rawValue, Date().timeIntervalSince1970, id]
        )
        if let urgency, urgency != item.urgency {
            writeUrgentOrder(urgentItems(for: item.urgency).filter { $0.id != id }, urgency: item.urgency)
            writeUrgentOrder(urgentItems(for: urgency), urgency: urgency)
        }
        refresh()
    }

    func toggleUrgentDone(_ id: Int) -> Bool {
        guard let item = urgent.first(where: { $0.id == id }) else { return false }
        let newValue = item.done ? 0 : 1
        _ = db.execute("UPDATE urgent SET done = ?, updated_at = ? WHERE id = ?", [newValue, Date().timeIntervalSince1970, id])
        refresh()
        return newValue == 1
    }

    func deleteUrgent(_ id: Int) {
        guard let item = urgent.first(where: { $0.id == id }) else { return }
        _ = db.execute("DELETE FROM urgent WHERE id = ?", [id])
        writeUrgentOrder(urgentItems(for: item.urgency).filter { $0.id != id }, urgency: item.urgency)
        refresh()
    }

    private func writeUrgentOrder(_ ordered: [UrgentItem], urgency: Urgency) {
        for (i, item) in ordered.enumerated() {
            _ = db.execute("UPDATE urgent SET position = ?, updated_at = ? WHERE id = ?", [i, Date().timeIntervalSince1970, item.id])
        }
    }

    // MARK: - Mini Mind Map

    func mindMapNode(_ n: MindMapNode, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return n.text.lowercased().contains(query.lowercased())
    }

    func mindMap(_ m: MindMap, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return m.title.lowercased().contains(query.lowercased())
    }

    func nodesForMap(_ mapID: Int) -> [MindMapNode] {
        mindMapNodes.filter { $0.mapId == mapID }
    }

    func rootNode(for mapID: Int) -> MindMapNode? {
        nodesForMap(mapID).first { $0.isRoot }
    }

    func children(of nodeID: Int, in mapID: Int) -> [MindMapNode] {
        nodesForMap(mapID).filter { $0.parentId == nodeID }
    }

    func addMindMap(title: String = "Untitled Map") -> Int {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Untitled Map" : trimmed
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO mindmaps (title, created_at, updated_at) VALUES (?, ?, ?)",
            [name, now, now]
        )
        let mapID = db.lastInsertID()
        _ = db.execute(
            "INSERT INTO mindmap_nodes (map_id, parent_id, text, color, x, y, created_at, updated_at) VALUES (?, NULL, 'Main idea', 'blue', ?, ?, ?, ?)",
            [mapID, Double(900), Double(600), now, now]
        )
        refresh()
        return mapID
    }

    func renameMindMap(id: Int, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE mindmaps SET title = ?, updated_at = ? WHERE id = ?",
            [trimmed, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func deleteMindMap(_ id: Int) {
        _ = db.execute("DELETE FROM mindmap_nodes WHERE map_id = ?", [id])
        _ = db.execute("DELETE FROM mindmaps WHERE id = ?", [id])
        refresh()
    }

    func addMindMapNode(mapID: Int, parentID: Int, text: String = "") {
        let now = Date().timeIntervalSince1970
        guard let parent = mindMapNodes.first(where: { $0.id == parentID }) else { return }
        let children = children(of: parentID, in: mapID)
        let offset = Double(children.count) * 150.0 - Double(children.count) * 30.0
        let x = parent.x + 230
        let y = parent.y + offset - Double(children.count) * 60.0 + 60.0
        _ = db.execute(
            "INSERT INTO mindmap_nodes (map_id, parent_id, text, color, x, y, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            [mapID, parentID, text, parent.color, x, y, now, now]
        )
        refresh()
    }

    func updateMindMapNodeText(_ id: Int, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = db.execute(
            "UPDATE mindmap_nodes SET text = ?, updated_at = ? WHERE id = ?",
            [trimmed, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func updateMindMapNodeColor(_ id: Int, color: String) {
        _ = db.execute(
            "UPDATE mindmap_nodes SET color = ?, updated_at = ? WHERE id = ?",
            [color, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func moveMindMapNode(_ id: Int, x: Double, y: Double) {
        _ = db.execute(
            "UPDATE mindmap_nodes SET x = ?, y = ?, updated_at = ? WHERE id = ?",
            [x, y, Date().timeIntervalSince1970, id]
        )
        if let idx = mindMapNodes.firstIndex(where: { $0.id == id }) {
            let n = mindMapNodes[idx]
            mindMapNodes[idx] = MindMapNode(
                id: n.id, mapId: n.mapId, parentId: n.parentId, text: n.text, color: n.color,
                x: x, y: y, createdAt: n.createdAt, updatedAt: Date()
            )
        }
    }

    func deleteMindMapNode(_ id: Int) {
        var toDelete: [Int] = [id]
        var queue = [id]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            for child in mindMapNodes where child.parentId == current {
                toDelete.append(child.id)
                queue.append(child.id)
            }
        }
        for nodeID in toDelete {
            _ = db.execute("DELETE FROM mindmap_nodes WHERE id = ?", [nodeID])
        }
        refresh()
    }

    // MARK: - Blog posts

    func blogPost(_ p: BlogPost, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        if p.title.lowercased().contains(q) { return true }
        if p.body.lowercased().contains(q) { return true }
        return p.tags.lowercased().contains(q)
    }

    func addBlogPost(title: String, body: String = "", tags: String = "", status: BlogPostStatus = .draft) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO blog_posts (title, body, status, tags, created_at, updated_at, published_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            [trimmed, body, status.rawValue, tags, now, now, status == .published ? now : nil]
        )
        refresh()
    }

    func updateBlogPost(id: Int, title: String? = nil, body: String? = nil, tags: String? = nil, status: BlogPostStatus? = nil) {
        guard let post = blogPosts.first(where: { $0.id == id }) else { return }
        let newStatus = status ?? post.status
        _ = db.execute(
            "UPDATE blog_posts SET title = ?, body = ?, status = ?, tags = ?, updated_at = ? WHERE id = ?",
            [title ?? post.title, body ?? post.body, newStatus.rawValue, tags ?? post.tags, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func setBlogPostStatus(_ id: Int, _ status: BlogPostStatus) {
        guard let post = blogPosts.first(where: { $0.id == id }) else { return }
        let now = Date().timeIntervalSince1970
        if status == .published && post.status != .published {
            _ = db.execute(
                "UPDATE blog_posts SET status = ?, published_at = ?, updated_at = ? WHERE id = ?",
                [status.rawValue, now, now, id]
            )
        } else if status == .draft {
            _ = db.execute(
                "UPDATE blog_posts SET status = ?, published_at = NULL, updated_at = ? WHERE id = ?",
                [status.rawValue, now, id]
            )
        }
        refresh()
    }

    func deleteBlogPost(_ id: Int) {
        _ = db.execute("DELETE FROM blog_posts WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Mini Slack

    private func seedSlackIfNeeded() {
        let settings = db.allSettings
        guard settings["slackSeeded"] != "true" else { return }
        insertSlackChannel(name: "general", color: "blue")
        db.setSetting("slackSeeded", "true")
        refresh()
    }

    func slackChannel(_ c: SlackChannel, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return c.name.lowercased().contains(query.lowercased())
    }

    func slackMessage(_ m: SlackMessage, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return m.text.lowercased().contains(q) || m.author.lowercased().contains(q)
    }

    func messages(in channelID: Int) -> [SlackMessage] {
        slackMessages.filter { $0.channelId == channelID }
    }

    func addSlackChannel(name: String, color: String = "blue") -> Int? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        _ = db.execute(
            "INSERT INTO slack_channels (name, color, created_at) VALUES (?, ?, ?)",
            [trimmed, color, Date().timeIntervalSince1970]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func renameSlackChannel(id: Int, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute("UPDATE slack_channels SET name = ? WHERE id = ?", [trimmed, id])
        refresh()
    }

    func deleteSlackChannel(_ id: Int) {
        _ = db.execute("DELETE FROM slack_messages WHERE channel_id = ?", [id])
        _ = db.execute("DELETE FROM slack_channels WHERE id = ?", [id])
        refresh()
    }

    func sendSlackMessage(channelID: Int, author: String = "Me", text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO slack_messages (channel_id, author, text, created_at) VALUES (?, ?, ?, ?)",
            [channelID, author, trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteSlackMessage(_ id: Int) {
        _ = db.execute("DELETE FROM slack_messages WHERE id = ?", [id])
        refresh()
    }

    private func insertSlackChannel(name: String, color: String) {
        _ = db.execute(
            "INSERT INTO slack_channels (name, color, created_at) VALUES (?, ?, ?)",
            [name, color, Date().timeIntervalSince1970]
        )
    }

    // MARK: - Calendar

    func calendarEvent(_ e: CalendarEvent, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return e.title.lowercased().contains(q) || e.note.lowercased().contains(q)
    }

    func events(on day: String) -> [CalendarEvent] {
        calendarEvents
            .filter { $0.day == day }
            .sorted {
                if $0.time != $1.time { return $0.time < $1.time }
                return $0.createdAt < $1.createdAt
            }
    }

    func eventsInMonth(of date: Date) -> [CalendarEvent] {
        let prefix = String(dayString(date).prefix(7))
        return calendarEvents.filter { $0.day.hasPrefix(prefix) }
    }

    func addCalendarEvent(title: String, day: String, time: String = "", color: String = "blue", note: String = "") {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO calendar_events (title, day, time, color, note, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            [trimmed, day, time, color, note, now, now]
        )
        refresh()
    }

    func updateCalendarEvent(id: Int, title: String? = nil, time: String? = nil, color: String? = nil, note: String? = nil) {
        guard let event = calendarEvents.first(where: { $0.id == id }) else { return }
        _ = db.execute(
            "UPDATE calendar_events SET title = ?, time = ?, color = ?, note = ?, updated_at = ? WHERE id = ?",
            [title ?? event.title, time ?? event.time, color ?? event.color, note ?? event.note, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func deleteCalendarEvent(_ id: Int) {
        _ = db.execute("DELETE FROM calendar_events WHERE id = ?", [id])
        refresh()
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

    // MARK: - Links

    func link(_ l: LinkItem, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return l.label.lowercased().contains(q) || l.url.lowercased().contains(q)
    }

    func addLink(label: String, url: String) {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let position = links.count
        _ = db.execute(
            "INSERT INTO links (label, url, position, created_at) VALUES (?, ?, ?, ?)",
            [label, trimmed, position, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func updateLink(id: Int, label: String? = nil, url: String? = nil) {
        guard let l = links.first(where: { $0.id == id }) else { return }
        _ = db.execute("UPDATE links SET label = ?, url = ? WHERE id = ?", [label ?? l.label, url ?? l.url, id])
        refresh()
    }

    func deleteLink(_ id: Int) {
        _ = db.execute("DELETE FROM links WHERE id = ?", [id])
        refresh()
    }

    func moveLink(_ id: Int, to newIndex: Int) {
        guard let link = links.first(where: { $0.id == id }) else { return }
        var ordered = links
        guard let fromIndex = ordered.firstIndex(where: { $0.id == id }) else { return }
        ordered.remove(at: fromIndex)
        ordered.insert(link, at: max(0, min(newIndex, ordered.count)))
        for (i, l) in ordered.enumerated() {
            _ = db.execute("UPDATE links SET position = ? WHERE id = ?", [i, l.id])
        }
        refresh()
    }

    // MARK: - 313 Cards

    func card(_ c: WordCard, matches query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        if c.word.lowercased().contains(q) { return true }
        if c.groupName.lowercased().contains(q) { return true }
        if c.wordsText.lowercased().contains(q) { return true }
        return false
    }

    func addCard(word: String, group: String = "", words: [String] = [], link: String = "") {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        let slot = (cards.map(\.slot).max() ?? 0) + 1
        let wordsText = words.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.joined(separator: "|")
        _ = db.execute(
            "INSERT INTO wordcards (slot, word, group_name, words, link, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            [slot, trimmed, group.trimmingCharacters(in: .whitespacesAndNewlines), wordsText, link, now, now]
        )
        refresh()
    }

    func updateCard(id: Int, word: String? = nil, group: String? = nil, words: [String]? = nil, link: String? = nil) {
        guard let c = cards.first(where: { $0.id == id }) else { return }
        let wordsText = (words ?? c.words).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.joined(separator: "|")
        _ = db.execute(
            "UPDATE wordcards SET word = ?, group_name = ?, words = ?, link = ?, updated_at = ? WHERE id = ?",
            [word ?? c.word, group ?? c.groupName, wordsText, link ?? c.link, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func deleteCard(_ id: Int) {
        _ = db.execute("DELETE FROM wordcards WHERE id = ?", [id])
        refresh()
    }

    func addAllEmptyCards(target: Int = 313) -> Int {
        let nextSlot = (cards.map(\.slot).max() ?? 0) + 1
        let toAdd = max(0, target - (nextSlot - 1))
        if toAdd == 0 { return 0 }
        let now = Date().timeIntervalSince1970
        for i in 0..<toAdd {
            _ = db.execute(
                "INSERT INTO wordcards (slot, word, group_name, words, link, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                [nextSlot + i, "", "Empty", "", "", now, now]
            )
        }
        refresh()
        return toAdd
    }

    func resetDeck(target: Int = 313) {
        _ = db.execute("DELETE FROM wordcards")
        let now = Date().timeIntervalSince1970
        for i in 0..<max(0, target) {
            _ = db.execute(
                "INSERT INTO wordcards (slot, word, group_name, words, link, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                [i + 1, "", "Empty", "", "", now, now]
            )
        }
        refresh()
    }

    var totalEmptySlots: Int {
        cards.filter { $0.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    var cardGroups: [String] {
        var seen: [String] = []
        for c in cards {
            let g = c.groupName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !g.isEmpty && !seen.contains(g) { seen.append(g) }
        }
        return seen
    }

    func exportCards() -> String? {
        struct CardDTO: Codable {
            let slot: Int
            let word: String
            var group: String
            var words: [String]
            var link: String
        }
        let dtos = cards.sorted(by: { $0.slot < $1.slot }).map { CardDTO(slot: $0.slot, word: $0.word, group: $0.groupName, words: $0.words, link: $0.link) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(dtos) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func importCards(fromJSON text: String) -> Int {
        guard let data = text.data(using: .utf8) else { return 0 }
        struct CardDTO: Decodable {
            let word: String
            var slot: Int?
            var group: String?
            var words: [String]?
            var link: String?
        }
        guard let dtos = try? JSONDecoder().decode([CardDTO].self, from: data) else { return 0 }
        var added = 0
        let now = Date().timeIntervalSince1970
        var nextSlot = (cards.map(\.slot).max() ?? 0) + 1
        for d in dtos {
            let w = d.word.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !w.isEmpty else { continue }
            let slot = d.slot ?? nextSlot
            if slot >= nextSlot { nextSlot = slot + 1 }
            _ = db.execute(
                "INSERT INTO wordcards (slot, word, group_name, words, link, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                [slot, w, d.group ?? "", (d.words ?? []).joined(separator: "|"), d.link ?? "", now, now]
            )
            added += 1
        }
        if added > 0 { refresh() }
        return added
    }

    // MARK: - Pomodoro

    var focusSessionsToday: Int {
        let dayStart = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        return pomodoros.filter { $0.mode == .focus && $0.endedAt != nil && $0.startedAt.timeIntervalSince1970 >= dayStart }.count
    }

    @discardableResult
    func addPomodoro(mode: PomodoroMode, startedAt: Date) -> Int {
        _ = db.execute("INSERT INTO pomodoro_sessions (mode, started_at) VALUES (?, ?)", [mode.rawValue, startedAt.timeIntervalSince1970])
        return db.lastInsertID()
    }

    func endPomodoro(id: Int) {
        _ = db.execute("UPDATE pomodoro_sessions SET ended_at = ? WHERE id = ?", [Date().timeIntervalSince1970, id])
        refresh()
    }

    // MARK: - Sprints

    func sprint(_ s: Sprint, matches query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        if s.name.lowercased().contains(q) { return true }
        if s.notes.lowercased().contains(q) { return true }
        return false
    }

    func story(_ s: Story, matches query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        return s.title.lowercased().contains(q)
    }

    func addSprint(name: String, startAt: Date?, endAt: Date?, notes: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO sprints (name, start_at, end_at, notes, done, created_at, updated_at) VALUES (?, ?, ?, ?, 0, ?, ?)",
            [trimmed, startAt?.timeIntervalSince1970, endAt?.timeIntervalSince1970, notes, now, now]
        )
        refresh()
    }

    func updateSprint(id: Int, name: String? = nil, startAt: Date? = nil, endAt: Date? = nil, notes: String? = nil, done: Bool? = nil) {
        guard let s = sprints.first(where: { $0.id == id }) else { return }
        let newDone = done ?? s.done
        _ = db.execute(
            "UPDATE sprints SET name = ?, start_at = ?, end_at = ?, notes = ?, done = ?, updated_at = ? WHERE id = ?",
            [name ?? s.name, startAt?.timeIntervalSince1970, endAt?.timeIntervalSince1970, notes ?? s.notes, newDone ? 1 : 0, Date().timeIntervalSince1970, id]
        )
        if let done, done && !s.done {
            addWin(text: "Sprint done: \(name ?? s.name)")
        } else {
            refresh()
        }
    }

    func deleteSprint(_ id: Int) {
        let storyIDs = stories.filter { $0.sprintId == id }.map { $0.id }
        for sid in storyIDs {
            _ = db.execute("DELETE FROM story_tasks WHERE story_id = ?", [sid])
        }
        _ = db.execute("DELETE FROM stories WHERE sprint_id = ?", [id])
        _ = db.execute("DELETE FROM sprints WHERE id = ?", [id])
        refresh()
    }

    func storiesForSprint(_ sprintId: Int) -> [Story] {
        stories.filter { $0.sprintId == sprintId }.sorted { $0.updatedAt < $1.updatedAt }
    }

    func addStory(sprintId: Int, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        _ = db.execute("INSERT INTO stories (sprint_id, title, created_at, updated_at) VALUES (?, ?, ?, ?)", [sprintId, trimmed, now, now])
        refresh()
    }

    func updateStory(id: Int, title: String? = nil, sprintId: Int? = nil) {
        guard let st = stories.first(where: { $0.id == id }) else { return }
        _ = db.execute("UPDATE stories SET title = ?, sprint_id = ?, updated_at = ? WHERE id = ?",
                       [title ?? st.title, sprintId ?? st.sprintId, Date().timeIntervalSince1970, id])
        refresh()
    }

    func deleteStory(_ id: Int) {
        _ = db.execute("DELETE FROM story_tasks WHERE story_id = ?", [id])
        _ = db.execute("DELETE FROM stories WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Tasks

    func tasksForStory(_ storyId: Int) -> [StoryTask] {
        storyTasks.filter { $0.storyId == storyId }.sorted { $0.updatedAt < $1.updatedAt }
    }

    func tasksForSprint(_ sprintId: Int) -> [StoryTask] {
        let sid = Set(storiesForSprint(sprintId).map { $0.id })
        return storyTasks.filter { sid.contains($0.storyId) }
    }

    func addTask(storyId: Int, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        _ = db.execute("INSERT INTO story_tasks (story_id, title, done, created_at, updated_at) VALUES (?, ?, 0, ?, ?)", [storyId, trimmed, now, now])
        refresh()
    }

    func updateTask(id: Int, title: String? = nil, done: Bool? = nil) {
        guard let t = storyTasks.first(where: { $0.id == id }) else { return }
        let newDone = done ?? t.done
        _ = db.execute("UPDATE story_tasks SET title = ?, done = ?, updated_at = ? WHERE id = ?",
                       [title ?? t.title, newDone ? 1 : 0, Date().timeIntervalSince1970, id])
        if let done, done && !t.done {
            addWin(text: "Task done: \(title ?? t.title)")
        } else {
            refresh()
        }
    }

    func deleteTask(_ id: Int) {
        _ = db.execute("DELETE FROM story_tasks WHERE id = ?", [id])
        refresh()
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

    private func loadLinks() -> [LinkItem] {
        db.query("SELECT * FROM links ORDER BY position ASC, created_at ASC").compactMap { row in
            guard let id = row["id"] as? Int, let url = row["url"] as? String, let created = row["created_at"] as? Double else { return nil }
            return LinkItem(id: id, label: row["label"] as? String ?? "", url: url, position: row["position"] as? Int ?? 0, createdAt: Date(timeIntervalSince1970: created))
        }
    }

    private func loadCards() -> [WordCard] {
        db.query("SELECT * FROM wordcards ORDER BY slot ASC, created_at ASC").compactMap { row in
            guard let id = row["id"] as? Int, let word = row["word"] as? String, let created = row["created_at"] as? Double else { return nil }
            return WordCard(
                id: id,
                slot: row["slot"] as? Int ?? 0,
                word: word,
                groupName: row["group_name"] as? String ?? "",
                words: (row["words"] as? String ?? "").split(separator: "|").map(String.init),
                link: row["link"] as? String ?? "",
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: row["updated_at"] as? Double ?? created)
            )
        }
    }

    private func loadPomodoros() -> [PomodoroSession] {
        db.query("SELECT * FROM pomodoro_sessions ORDER BY started_at DESC").compactMap { row in
            guard let id = row["id"] as? Int, let modeRaw = row["mode"] as? String, let mode = PomodoroMode(rawValue: modeRaw), let created = row["started_at"] as? Double else { return nil }
            return PomodoroSession(id: id, mode: mode, startedAt: Date(timeIntervalSince1970: created), endedAt: (row["ended_at"] as? Double).map { Date(timeIntervalSince1970: $0) })
        }
    }

    private func loadSprints() -> [Sprint] {
        db.query("SELECT * FROM sprints ORDER BY created_at DESC").compactMap { row in
            guard let id = row["id"] as? Int, let name = row["name"] as? String, let created = row["created_at"] as? Double else { return nil }
            return Sprint(
                id: id,
                name: name,
                startAt: (row["start_at"] as? Double).map { Date(timeIntervalSince1970: $0) },
                endAt: (row["end_at"] as? Double).map { Date(timeIntervalSince1970: $0) },
                notes: row["notes"] as? String ?? "",
                done: (row["done"] as? Int ?? 0) == 1,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: row["updated_at"] as? Double ?? created)
            )
        }
    }

    private func loadStories() -> [Story] {
        db.query("SELECT * FROM stories ORDER BY created_at ASC").compactMap { row in
            guard let id = row["id"] as? Int, let sprintID = row["sprint_id"] as? Int, let title = row["title"] as? String, let created = row["created_at"] as? Double else { return nil }
            return Story(id: id, sprintId: sprintID, title: title, createdAt: Date(timeIntervalSince1970: created), updatedAt: Date(timeIntervalSince1970: row["updated_at"] as? Double ?? created))
        }
    }

    private func loadStoryTasks() -> [StoryTask] {
        db.query("SELECT * FROM story_tasks ORDER BY created_at ASC").compactMap { row in
            guard let id = row["id"] as? Int, let storyID = row["story_id"] as? Int, let title = row["title"] as? String, let created = row["created_at"] as? Double else { return nil }
            return StoryTask(id: id, storyId: storyID, title: title, done: (row["done"] as? Int ?? 0) == 1, createdAt: Date(timeIntervalSince1970: created), updatedAt: Date(timeIntervalSince1970: row["updated_at"] as? Double ?? created))
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

    private func loadFails() -> [Fail] {
        db.query("SELECT * FROM fails ORDER BY created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let text = row["text"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return Fail(
                id: id,
                text: text,
                bookmarked: (row["bookmarked"] as? Int ?? 0) == 1,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func loadInterNotes() -> [InterNote] {
        db.query("SELECT * FROM interstitial_notes ORDER BY created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let text = row["text"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return InterNote(id: id, text: text, createdAt: Date(timeIntervalSince1970: created))
        }
    }

    private func fetchBucksFiltered(_ q: String) -> [Buck] {
        let query = q.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = loadBucks()
        guard !query.isEmpty else { return all }
        return all.filter { buck($0, matches: query) }
    }

    private func loadBucks() -> [Buck] {
        let order = "CASE status WHEN 'active' THEN 0 WHEN 'paused' THEN 1 ELSE 2 END"
        return db.query("SELECT * FROM bucks ORDER BY \(order), updated_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let statusRaw = row["status"] as? String,
                let notes = row["notes"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            let status = BuckStatus(rawValue: statusRaw) ?? .active
            return Buck(
                id: id,
                title: title,
                status: status,
                notes: notes,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    private func loadFocus() -> [Focus] {
        db.query("SELECT * FROM focus ORDER BY started_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let text = row["text"] as? String,
                let note = row["note"] as? String,
                let started = row["started_at"] as? Double
            else { return nil }
            let ended = (row["ended_at"] as? Double).map { Date(timeIntervalSince1970: $0) }
            return Focus(id: id, text: text, note: note, startedAt: Date(timeIntervalSince1970: started), endedAt: ended)
        }
    }

    private func loadParallel() -> [ParallelItem] {
        db.query("SELECT * FROM parallel ORDER BY lane ASC, created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let lane = row["lane"] as? Int,
                let text = row["text"] as? String,
                let note = row["note"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return ParallelItem(id: id, lane: lane, text: text, note: note, createdAt: Date(timeIntervalSince1970: created))
        }
    }

    private func loadProjects() -> [Project] {
        let order = "CASE status WHEN 'working' THEN 0 WHEN 'inProgress' THEN 1 ELSE 2 END, updated_at DESC"
        return db.query("SELECT * FROM projects ORDER BY \(order)").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let name = row["name"] as? String,
                let statusRaw = row["status"] as? String,
                let startNote = row["start_note"] as? String,
                let stopNote = row["stop_note"] as? String,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return Project(
                id: id,
                name: name,
                status: ProjectStatus(rawValue: statusRaw) ?? .inProgress,
                startNote: startNote,
                stopNote: stopNote,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    private func loadDeepWork() -> [DeepWorkSession] {
        db.query("SELECT * FROM deepwork_sessions ORDER BY started_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let minutes = row["minutes"] as? Int,
                let started = row["started_at"] as? Double,
                let ended = row["ended_at"] as? Double,
                let completed = row["completed"] as? Int
            else { return nil }
            return DeepWorkSession(
                id: id,
                minutes: minutes,
                startedAt: Date(timeIntervalSince1970: started),
                endedAt: Date(timeIntervalSince1970: ended),
                completed: completed == 1
            )
        }
    }

    private func loadSchedule() -> [ScheduleEntry] {
        db.query("SELECT * FROM schedule").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let day = row["day"] as? Int,
                let slot = row["slot"] as? Int,
                let task = row["task"] as? String,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return ScheduleEntry(id: id, day: day, slot: slot, task: task, updatedAt: Date(timeIntervalSince1970: updated))
        }
    }

    private func loadHolding() -> [HoldingItem] {
        db.query("SELECT * FROM holding ORDER BY created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let text = row["text"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return HoldingItem(
                id: id,
                text: text,
                bookmarked: (row["bookmarked"] as? Int ?? 0) == 1,
                done: (row["done"] as? Int ?? 0) == 1,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func loadUrgent() -> [UrgentItem] {
        db.query("SELECT * FROM urgent ORDER BY urgency ASC, position ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let urgencyRaw = row["urgency"] as? Int,
                let urgency = Urgency(rawValue: urgencyRaw),
                let text = row["text"] as? String,
                let note = row["note"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return UrgentItem(
                id: id,
                urgency: urgency,
                text: text,
                note: note,
                position: position,
                done: (row["done"] as? Int ?? 0) == 1,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    private func loadMindMaps() -> [MindMap] {
        db.query("SELECT * FROM mindmaps ORDER BY created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return MindMap(
                id: id,
                title: title,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    private func loadMindMapNodes() -> [MindMapNode] {
        db.query("SELECT * FROM mindmap_nodes").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let mapID = row["map_id"] as? Int,
                let text = row["text"] as? String,
                let x = row["x"] as? Double,
                let y = row["y"] as? Double,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return MindMapNode(
                id: id,
                mapId: mapID,
                parentId: row["parent_id"] as? Int,
                text: text,
                color: row["color"] as? String ?? "blue",
                x: x,
                y: y,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    private func loadBlogPosts() -> [BlogPost] {
        db.query("SELECT * FROM blog_posts ORDER BY updated_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let body = row["body"] as? String,
                let statusRaw = row["status"] as? String,
                let status = BlogPostStatus(rawValue: statusRaw),
                let tags = row["tags"] as? String,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return BlogPost(
                id: id,
                title: title,
                body: body,
                status: status,
                tags: tags,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated),
                publishedAt: (row["published_at"] as? Double).map { Date(timeIntervalSince1970: $0) }
            )
        }
    }

    private func loadSlackChannels() -> [SlackChannel] {
        db.query("SELECT * FROM slack_channels ORDER BY created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let name = row["name"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return SlackChannel(
                id: id,
                name: name,
                color: row["color"] as? String ?? "blue",
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func loadSlackMessages() -> [SlackMessage] {
        db.query("SELECT * FROM slack_messages ORDER BY created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let channelID = row["channel_id"] as? Int,
                let author = row["author"] as? String,
                let text = row["text"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return SlackMessage(
                id: id,
                channelId: channelID,
                author: author,
                text: text,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func loadCalendarEvents() -> [CalendarEvent] {
        db.query("SELECT * FROM calendar_events ORDER BY day ASC, time ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let day = row["day"] as? String,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return CalendarEvent(
                id: id,
                title: title,
                day: day,
                time: row["time"] as? String ?? "",
                color: row["color"] as? String ?? "blue",
                note: row["note"] as? String ?? "",
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
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
