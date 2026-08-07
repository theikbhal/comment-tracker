import SwiftUI
import AppKit

struct FocusView: View {
    @EnvironmentObject var store: Store
    @State private var draft = ""
    @State private var noteDraft = ""

    private var active: Focus? { store.currentFocus }

    private var history: [Focus] { store.focusSessions.filter { !$0.isActive } }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 20) {
                    if let focus = active {
                        activeCard(focus)
                    } else {
                        starterCard
                    }
                    if !history.isEmpty {
                        historySection
                    }
                }
                .padding(20)
                .frame(maxWidth: 620, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Focus")
                    .font(.title.bold())
                Text(active == nil ? "No active focus" : "Focused on one thing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(history.count) completed focus sessions")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(16)
    }

    private var starterCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("One thing at a time", systemImage: "scope")
                .font(.headline)
            HStack(spacing: 10) {
                TextField("What's the one thing you're doing now?", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(start)
                Button("Start focus", action: start)
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Text("Pick the single most important thing. Everything else waits.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.16), lineWidth: 1))
    }

    private func activeCard(_ focus: Focus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "scope")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.indigo.gradient, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text("CURRENT FOCUS")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.indigo)
                    Text(focus.text)
                        .font(.title3.bold())
                        .textSelection(.enabled)
                    TimelineView(.periodic(from: focus.startedAt, by: 1)) { context in
                        Text("\(context.date.timeIntervalSince(focus.startedAt).elapsedString) · started \(focus.startedAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button {
                    store.endFocus()
                } label: {
                    Label("End focus", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }
            Divider()
            TextField("Note for this focus session…", text: $noteDraft)
                .textFieldStyle(.plain)
                .onSubmit {
                    store.updateFocusNote(focus.id, note: noteDraft)
                }
                .padding(8)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(Color.indigo.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.indigo.opacity(0.3), lineWidth: 1.5))
        .onAppear {
            noteDraft = focus.note
        }
        .onChange(of: focus.id) { _, _ in
            noteDraft = focus.note
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Past focus")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            VStack(spacing: 0) {
                ForEach(history) { f in
                    FocusRowView(focus: f)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.14), lineWidth: 1))
        }
    }

    private func start() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.startFocus(text: trimmed)
        draft = ""
    }
}

// MARK: - Row

struct FocusRowView: View {
    @EnvironmentObject var store: Store
    let focus: Focus

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "scope")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.indigo.gradient, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(focus.text)
                    .font(.subheadline.weight(.semibold))
                Text(focus.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !focus.note.isEmpty {
                    Text(focus.note)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            if let ended = focus.endedAt {
                Text(ended.timeIntervalSince(focus.startedAt).elapsedString)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                store.deleteFocus(focus.id)
            } label: {
                Label("Delete session", systemImage: "trash")
            }
        }
    }
}

// MARK: - Duration helper

extension TimeInterval {
    var elapsedString: String {
        let total = Int(self)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        if m > 0 { return String(format: "%dm %02ds", m, s) }
        return String(format: "%ds", s)
    }
}