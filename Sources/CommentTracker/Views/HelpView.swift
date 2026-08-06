import SwiftUI

struct HelpView: View {
    @EnvironmentObject var store: Store
    @State private var goalText: String = ""
    @State private var subGoalText: String = ""
    @State private var peopleGoalText: String = ""
    @State private var showDataPath = false

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
                shortcutsCard
                dataCard
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

    private var shortcutsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Keyboard shortcuts", systemImage: "keyboard")
                .font(.headline)
            HStack(spacing: 24) {
                shortcutRow("⌘ N", "Add Comment")
                shortcutRow("⇧ ⌘ S", "Start / End Session")
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
