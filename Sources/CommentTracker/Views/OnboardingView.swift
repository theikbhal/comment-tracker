import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var step = 1
    @State private var goalText = "313"
    @State private var subGoal: Int = 30
    @State private var customSubGoal = ""

    var body: some View {
        VStack(spacing: 0) {
            switch step {
            case 1: welcomeStep
            case 2: platformsStep
            case 3: videosStep
            default: trackerStep
            }
        }
        .frame(width: 580)
    }

    private var welcomeStep: some View {
        VStack(spacing: 22) {
            Image(systemName: "target")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(.blue.gradient)
                .padding(.top, 36)

            VStack(spacing: 6) {
                Text("Comment Tracker")
                    .font(.largeTitle.bold())
                Text("Push your daily commenting goal.\nTrack time. See how much you can do.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            dailyGoalRow

            subGoalSection

            Button {
                store.updateGoal(parsedGoal)
                store.updateSubGoal(subGoal)
                step = 2
            } label: {
                Label("Continue", systemImage: "arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 28)
        }
        .padding(28)
    }

    private var dailyGoalRow: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Daily goal")
                        .font(.headline)
                    Text("313 is a big number — that's why we use sub-goals.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                TextField("313", text: $goalText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .multilineTextAlignment(.trailing)
            }
            Stepper(value: goalBinding, in: 1...2000) {
                EmptyView()
            }
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private var subGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Sub-goal — what you push for today")
                    .font(.headline)
                Text("Pick the level you're comfortable with. You can change it anytime.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                ForEach(SubGoalPreset.allCases) { preset in
                    presetChip(preset)
                }
            }

            HStack(spacing: 8) {
                TextField("Custom", text: $customSubGoal)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
                    .multilineTextAlignment(.center)
                    .onSubmit {
                        if let v = Int(customSubGoal), v > 0 {
                            subGoal = v
                        }
                    }
                Text("custom")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Current: \(subGoal)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func presetChip(_ preset: SubGoalPreset) -> some View {
        let selected = subGoal == preset.rawValue
        return Button {
            subGoal = preset.rawValue
            customSubGoal = ""
        } label: {
            Text(preset.label)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selected ? Color.blue : Color.gray.opacity(0.2), lineWidth: selected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var platformsStep: some View {
        VStack(spacing: 22) {
            VStack(spacing: 6) {
                Text("Focus: x.com")
                    .font(.title2.bold())
                    .padding(.top, 32)
                Text("For now, X is your primary channel. YouTube and Instagram stay available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                platformRow(.x, detail: "Primary — your main commenting channel", focus: true)
                platformRow(.yt, detail: "Other — available when you're ready")
                platformRow(.ig, detail: "Secondary — available when you're ready")
            }

            Text("Your data stays on this Mac in a local SQLite database.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                store.updateGoal(parsedGoal)
                store.updateSubGoal(subGoal)
                step = 3
            } label: {
                Label("Continue", systemImage: "arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 28)
        }
        .padding(28)
    }

    private var videosStep: some View {
        VStack(spacing: 22) {
            VStack(spacing: 6) {
                Text("Videos to watch")
                    .font(.title2.bold())
                    .padding(.top, 32)
                Text("Save YouTube, X and Instagram reels on a Trello-style board.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                videoRow(.holding, detail: "Queue — watch whenever")
                videoRow(.urgent, detail: "Watch first, time-sensitive")
                videoRow(.important, detail: "High value")
                videoRow(.daily, detail: "Daily Watch")
                videoRow(.weekly, detail: "Weekly Watch")
                videoRow(.monthly, detail: "Monthly Watch")
            }

            Text("Cards are searchable, draggable between lists, and open the video in your browser.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                store.updateGoal(parsedGoal)
                store.updateSubGoal(subGoal)
                step = 4
            } label: {
                Label("Continue", systemImage: "arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 28)
        }
        .padding(28)
    }

    private var trackerStep: some View {
        VStack(spacing: 22) {
            VStack(spacing: 6) {
                Text("Track your daily routines")
                    .font(.title2.bold())
                    .padding(.top, 32)
                Text("Namaz, Quran, zikr, fasting, family, health, business and more.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                trackerRow("Namaz", detail: "Fajr · Dhuhr · Asr · Maghrib · Isha — each with checkboxes and daily notes")
                trackerRow("Quran & Zikr", detail: "Listen one para · morning/evening zikr · 1000 darood · 1000 astaghfar counters")
                trackerRow("Fasting & Masjid", detail: "Fasting (Ramadan + Thursdays) · jamaat (3/month, 40/year) · attend masjid")
                trackerRow("Family & Parenting", detail: "Wife, parents, relatives, kids — listen, help, talk")
                trackerRow("Health & Business", detail: "Steps, diet · app build, content, sales, automation")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Every tracker has a calendar view with notes. Turn any on or off in Manage.")
                    .font(.caption)
                Text("Thoughts keeps your good ideas in a Trello board — hit “Pick for me” when stuck.")
                    .font(.caption)
                Text("Wins celebrates what you get done. Sprints + Pomodoro help you focus and ship — finishing a task wins automatically.")
                    .font(.caption)
                Text("Links and 313 Cards are quick lists you can search, export and import.")
                    .font(.caption)
                Text("Back up anytime from Help → Backup & Restore so your data is never lost.")
                    .font(.caption)
                Text("Press ⌘K to search everything in the app.")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                store.updateGoal(parsedGoal)
                store.updateSubGoal(subGoal)
                store.finishOnboarding()
                dismiss()
            } label: {
                Label("Start Tracking", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 28)
        }
        .padding(28)
    }

    private func trackerRow(_ title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 36, height: 36)
                .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func videoRow(_ stage: VideoStage, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: stage.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(stage.color)
                .frame(width: 36, height: 36)
                .background(stage.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 1) {
                Text(stage.displayName)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func platformRow(_ platform: Platform, detail: String, focus: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: platform.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(platform.color.gradient, in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text("\(platform.displayName) — \(platform.handle)")
                        .font(.subheadline.weight(.semibold))
                    if focus {
                        Label("FOCUS", systemImage: "scope")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(platform.color, in: Capsule())
                    }
                }
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private var parsedGoal: Int {
        Int(goalText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 313
    }

    private var goalBinding: Binding<Int> {
        Binding(
            get: { parsedGoal },
            set: { goalText = "\($0)" }
        )
    }
}
