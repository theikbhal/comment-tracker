import SwiftUI

struct TodayView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                HStack(alignment: .top, spacing: 18) {
                    progressPanel
                        .frame(width: 270)
                    VStack(spacing: 18) {
                        statsRow
                        platformGrid
                    }
                    .frame(maxWidth: .infinity)
                }
                sessionPanel
                milestonePanel
            }
            .padding(22)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showingAdd) {
            AddCommentView()
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today's push")
                    .font(.title.bold())
                Text(todayTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showingAdd = true
            } label: {
                Label("Add Comment", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut("n", modifiers: .command)
        }
    }

    private var todayTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    private var progressPanel: some View {
        VStack(spacing: 12) {
            ProgressRing(progress: store.subGoalProgress)
                .frame(width: 170, height: 170)
            VStack(spacing: 2) {
                Text("\(store.todayCount) / \(store.subGoal)")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .monospacedDigit()
                Text("sub-goal · \(store.remainingSubGoal) to go")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 4) {
                HStack {
                    Text("Daily")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(store.todayCount) / \(store.goal)")
                        .font(.caption2.weight(.semibold))
                        .monospacedDigit()
                }
                ProgressView(value: store.progress)
                    .tint(.purple)
            }
            milestoneBadge
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var milestoneBadge: some View {
        if store.todayCount > 0, let m = Milestone.reached(by: store.subGoalProgress) {
            if m.isWin {
                Label("You already won \(m.label) of your sub-goal!", systemImage: "trophy.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.yellow.opacity(0.18), in: Capsule())
                    .foregroundStyle(.yellow)
            } else {
                Label("\(m.label) reached — keep pushing", systemImage: "flame.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.orange.opacity(0.16), in: Capsule())
                    .foregroundStyle(.orange)
            }
        } else if let next = Milestone.next(after: store.subGoalProgress) {
            let nextCount = max(1, Int((Double(store.subGoal) * next.fraction).rounded()) - store.todayCount)
            Text("Next: \(next.label) (\(nextCount) comments)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatBadge(
                title: "comments / hour",
                value: String(format: "%.1f", store.pacePerHour),
                systemImage: "gauge.with.dots.needle.67percent"
            )
            StatBadge(
                title: "toward sub-goal",
                value: "\(store.todayCount) / \(store.subGoal)",
                systemImage: "flag.checkered"
            )
            StatBadge(
                title: "all-time",
                value: "\(store.totalCount)",
                systemImage: "chart.line.uptrend.xyaxis"
            )
        }
    }

    private var platformGrid: some View {
        VStack(spacing: 10) {
            PlatformCard(
                platform: .x,
                count: store.todayByPlatform[.x] ?? 0,
                goal: store.subGoal,
                isFocus: true
            )
            HStack(spacing: 10) {
                PlatformCard(
                    platform: .yt,
                    count: store.todayByPlatform[.yt] ?? 0,
                    goal: store.subGoal
                )
                PlatformCard(
                    platform: .ig,
                    count: store.todayByPlatform[.ig] ?? 0,
                    goal: store.subGoal
                )
            }
        }
    }

    private var sessionPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Session", systemImage: "timer")
                    .font(.headline)
                Spacer()
                if let session = store.activeSession {
                    Text("\(session.commentsAdded) comments this session")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let session = store.activeSession {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Active")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatElapsed(Date().timeIntervalSince(session.startedAt)))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Started")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(session.startedAt.formatted(date: .omitted, time: .shortened))
                            .font(.headline)
                    }
                    Button("End Session") {
                        store.endSession()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding(14)
                .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No active session")
                            .font(.headline)
                        Text("Start one and watch the clock — see how much you can push.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        store.startSession()
                    } label: {
                        Label("Start Session", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding(14)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }

    private var milestonePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Milestones", systemImage: "flag.checkered")
                    .font(.headline)
                Spacer()
                if let next = Milestone.next(after: store.subGoalProgress) {
                    Text("next: \(next.label)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("sub-goal reached 🎉")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }
            HStack(spacing: 8) {
                ForEach(Milestone.all) { m in
                    milestoneChip(m)
                }
            }
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }

    private func milestoneChip(_ m: Milestone) -> some View {
        let reached = m.fraction <= store.subGoalProgress
        let count = max(1, Int((Double(store.subGoal) * m.fraction).rounded()))
        return VStack(spacing: 2) {
            Image(systemName: reached ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(reached ? .green : Color.gray.opacity(0.4))
            Text(m.label)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
            Text("\(count)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(reached ? Color.green.opacity(0.12) : Color.gray.opacity(0.05))
        )
    }
}
