import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("History")
                        .font(.title.bold())
                    Text("Last 7 days and your past sessions.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    StatBadge(
                        title: "all-time comments",
                        value: "\(store.totalCount)",
                        systemImage: "bubble.left.and.bubble.right.fill"
                    )
                    StatBadge(
                        title: "sessions",
                        value: "\(store.totalSessions)",
                        systemImage: "timer"
                    )
                    StatBadge(
                        title: "time tracked",
                        value: formatHours(store.totalTime),
                        systemImage: "clock.fill"
                    )
                }

                chartCard

                if store.sessions.isEmpty {
                    emptySessions
                } else {
                    sessionsCard
                }
            }
            .padding(22)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Last 7 days", systemImage: "chart.bar.fill")
                .font(.headline)
            Chart(store.weeklyCounts) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Comments", item.count)
                )
                .foregroundStyle(
                    Color.blue.gradient
                )
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 220)
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }

    private var sessionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sessions", systemImage: "list.bullet.rectangle")
                .font(.headline)
            VStack(spacing: 0) {
                ForEach(Array(store.sessions.prefix(20).enumerated()), id: \.element.id) { index, session in
                    sessionRow(session)
                    if index < store.sessions.prefix(20).count - 1 {
                        Divider()
                    }
                }
            }
            .padding(6)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }

    private func sessionRow(_ session: Session) -> some View {
        HStack(spacing: 12) {
            Image(systemName: session.isActive ? "record.circle" : "checkmark.circle")
                .foregroundStyle(session.isActive ? Color.red : Color.green)
            VStack(alignment: .leading, spacing: 1) {
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.medium))
                Text(session.isActive ? "Active now" : "Duration \(formatDuration(session.duration))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                Text("\(session.commentsAdded)")
                    .font(.headline)
                    .monospacedDigit()
                Text("comments")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private var emptySessions: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("No sessions yet")
                    .font(.headline)
                Text("Start a session on the Today tab and time your push.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(30)
            Spacer()
        }
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
}
