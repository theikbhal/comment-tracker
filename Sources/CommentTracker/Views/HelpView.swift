import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct HelpView: View {
    @EnvironmentObject var store: Store
    @State private var goalText: String = ""
    @State private var subGoalText: String = ""
    @State private var peopleGoalText: String = ""
    @State private var showDataPath = false
    @State private var backupMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Help")
                        .font(.title.bold())
                    Text("How to use Comment Tracker.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                goalCard
                subGoalCard
                peopleGoalCard
                howToCard
                trackerCard
                thoughtsCard
                winsCard
                linksCard
                cardsCard
                pomodoroCard
                sprintsCard
                videosCard
                searchCard
                shortcutsCard
                dataCard
                backupCard
                roadmapCard
                aboutCard
            }
            .padding(22)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            goalText = "\(store.goal)"
            subGoalText = "\(store.subGoal)"
            peopleGoalText = "\(store.peopleGoal)"
        }
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Daily Goal", systemImage: "target")
                .font(.headline)
            HStack {
                TextField("Daily goal", text: $goalText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                Button("Save") {
                    store.updateGoal(Int(goalText) ?? 313)
                }
                .buttonStyle(.borderedProminent)
                Text("Default 313 · minimum pass 3")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private var subGoalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Sub-goal — today's comfortable push", systemImage: "flag.checkered")
                .font(.headline)
            Text("Smaller target so the big daily number doesn't feel overwhelming. Change it to any level you like.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(SubGoalPreset.allCases) { preset in
                    Button {
                        subGoalText = "\(preset.rawValue)"
                        store.updateSubGoal(preset.rawValue)
                    } label: {
                        Text(preset.label)
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .frame(width: 48)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(store.subGoal == preset.rawValue ? Color.blue.opacity(0.2) : Color.gray.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                TextField("Custom", text: $subGoalText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
                    .onSubmit {
                        store.updateSubGoal(Int(subGoalText) ?? 30)
                    }
                Button("Set") {
                    store.updateSubGoal(Int(subGoalText) ?? 30)
                }
                .buttonStyle(.bordered)
            }
            Text("Current sub-goal: \(store.subGoal) comments")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
        }
        .card()
    }

    private var peopleGoalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("People Goal", systemImage: "person.2")
                .font(.headline)
            Text("How many people you're tracking on the People board. Default 313.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                TextField("People goal", text: $peopleGoalText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                Button("Save") {
                    store.updatePeopleGoal(Int(peopleGoalText) ?? 313)
                }
                .buttonStyle(.borderedProminent)
                Spacer()
                Text("Tracking \(store.totalPeople)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private var howToCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("How it works", systemImage: "questionmark.circle")
                .font(.headline)
            VStack(alignment: .leading, spacing: 6) {
                row("1", "Set your daily goal + sub-goal", "Default daily goal is 313, sub-goal 30. Pick any level you're comfortable with.")
                row("2", "Start a session", "Hit Start Session, it times your push so you can see how much you can do.")
                row("3", "Add a comment per post", "Pick the platform (x.com is your focus), tap Add Comment. Optional note + link.")
                row("4", "Watch milestones", "Hit 1% of your sub-goal and you've already won — keep going through 5%, 10%, 25%, 50%, 75%, 100%.")
            }
            .padding(10)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
        }
        .card()
    }

    private var trackerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Tracker — daily routines", systemImage: "checklist")
                .font(.headline)
            Text("Track any daily habit with a checkbox or a counter. Included: Namaz (5), Quran (1 para), Zikr (morning/evening, 1000 darood, 1000 astaghfar), Dua, Fasting (Ramadan + Thursdays), Jamaat (3/month · 40/year · Sunday night), Masjid, Family, Parents, Relatives, Parenting, Friends, Health, Business.")
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 5) {
                Text("• Checkboxes mark done/not done; counters track up to a daily target")
                    .font(.caption)
                Text("• Every tracker has a monthly calendar — tap any day to set count + note")
                    .font(.caption)
                Text("• Manage (gear icon) turns any tracker on or off; add custom trackers with your own icon, color and target")
                    .font(.caption)
            }
            .padding(10)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
        }
        .card()
    }

    private var searchCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Search everything", systemImage: "magnifyingglass")
                .font(.headline)
            Text("Press ⌘K to search across tabs, trackers, people and videos. Type, then click (or Enter) to jump straight to the item.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var thoughtsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Thoughts — don't lose an idea", systemImage: "lightbulb")
                .font(.headline)
            Text("A Trello-style board with three lists — Long-term, This week, Doing. Add thoughts one at a time or paste a batch (one per line), drag them to reorder or move between lists.")
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 5) {
                Text("• “Pick for me” (🎲) chooses a random thought when you can’t decide")
                    .font(.caption)
                Text("• “Start doing” moves a thought to the Doing list")
                    .font(.caption)
            }
            .padding(10)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
        }
        .card()
    }

    private var winsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Wins — celebrate the small stuff", systemImage: "party.popper")
                .font(.headline)
            Text("A Twitter/X-style timeline of your wins. Newest at the top, older below. Bookmark the ones that matter and filter to them anytime.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("• Just won something? Type it in the compose box and hit Celebrate.")
                    .font(.caption)
        }
        .card()
    }

    private var linksCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Links", systemImage: "link")
                .font(.headline)
            Text("A simple list of links. Add one, click to open in your browser, drag to reorder, edit or delete. Perfect for a quick set of bookmarks.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

private var cardsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("313 Cards — one word per card", systemImage: "square.grid.3x3")
                .font(.headline)
            Text("A deck of one-word cards. Tap a card to add a dialog with up to 5 related words and an optional link. Group cards under a name you can search by, and export/import the whole deck as JSON.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("“Add 313 empty” tops the deck up to 313 blank cards to fill in. “Reset” wipes the deck and gives you a fresh set of 313 empty cards. “Hide empty” keeps the grid clean.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var pomodoroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Pomodoro", systemImage: "timer")
                .font(.headline)
            Text("Classic focus timer — Focus 25 / Short break 5 / Long break 15. Start with Space, auto-switches to a break when a focus session ends, and counts your sessions.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var sprintsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Sprints — stories & tasks", systemImage: "flag")
                .font(.headline)
            Text("Time-boxed sprints (30 min / 1 hr / 2 hrs). Add stories, break each story into tasks, and move stories between sprints. Marking a task or an entire sprint done automatically adds a Win to your feed.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var videosCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Videos board", systemImage: "play.rectangle")
                .font(.headline)
            Text("Save videos you want to watch on a Trello-style board. Add YouTube, X video or Instagram reel links.")
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 5) {
                Text("Lists: Holding (queue) · Urgent · Important · Daily Watch · Weekly Watch · Monthly Watch")
                    .font(.caption)
                Text("• Search filters across title, notes, links and comments")
                    .font(.caption)
                Text("• Drag cards between lists and reorder them")
                    .font(.caption)
                Text("• Double-click a card to edit, add comments, or open the video in your browser")
                    .font(.caption)
            }
            .padding(10)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
        }
        .card()
    }

    private var shortcutsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Keyboard shortcuts", systemImage: "keyboard")
                .font(.headline)
            HStack(spacing: 24) {
                shortcutRow("⌘ N", "Add Comment")
                shortcutRow("⇧ ⌘ S", "Start / End Session")
                shortcutRow("⌘ K", "Search Everything")
            }
        }
        .card()
    }

    private var dataCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Your data", systemImage: "internaldrive")
                .font(.headline)
            Text("Everything is stored locally in a SQLite database on this Mac — nothing leaves your machine.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button(showDataPath ? DatabaseManager.shared.databaseURL.path : "Show database path") {
                showDataPath.toggle()
            }
            .buttonStyle(.link)
            .help("Local SQLite file")
        }
        .card()
    }

    private var backupCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Backup & Restore", systemImage: "externaldrive.badge.checkmark")
                .font(.headline)
            Text("Everything lives in one SQLite file. Back it up anytime, and restore from any previous backup to bring your data back — nothing is ever lost.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Button {
                    exportBackup()
                } label: {
                    Label("Backup now…", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
                .help("Save a full copy of your data as a .sqlite file")
                Button {
                    importBackup()
                } label: {
                    Label("Restore…", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(.bordered)
                .help("Replace your data from a previous backup .sqlite file")
                if !backupMessage.isEmpty {
                    Text(backupMessage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .card()
    }

    private func exportBackup() {
        let panel = NSSavePanel()
        panel.title = "Back up Comment Tracker data"
        panel.nameFieldStringValue = "CommentTracker-backup-\(backupStamp()).sqlite"
        panel.allowedContentTypes = [.data]
        if panel.runModal() == .OK, let url = panel.url {
            backupMessage = store.backup(to: url) ? "Backup saved ✓" : "Backup failed"
        }
    }

    private func importBackup() {
        let panel = NSOpenPanel()
        panel.title = "Choose a backup to restore"
        panel.allowedContentTypes = [.data]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Restore this backup?"
        alert.informativeText = "Your current data will be replaced with the backup. Your current data is kept as a safety copy (comments-pre-restore.sqlite). This cannot be undone."
        alert.addButton(withTitle: "Restore")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        backupMessage = store.restore(from: url) ? "Restored ✓" : "Restore failed"
    }

    private func backupStamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmmss"
        return f.string(from: Date())
    }

    private var roadmapCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Roadmap", systemImage: "map")
                .font(.headline)
            Text("v1.0 · tracking core — today, sub-goals, sessions, milestones, local SQLite. Next up: streaks, reminders, exports, menu-bar widget. See ROADMAP.md in the repo.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("About", systemImage: "info.circle")
                .font(.headline)
            Text("Comment Tracker v1.0.0 · Swift + SwiftUI + SQLite")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private func row(_ n: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(n)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.blue))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func shortcutRow(_ keys: String, _ label: String) -> some View {
        HStack(spacing: 8) {
            Text(keys)
                .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 6))
            Text(label)
                .font(.subheadline)
        }
    }
}

private struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.12), lineWidth: 1)
            )
    }
}

extension View {
    func card() -> some View {
        modifier(CardModifier())
    }
}
