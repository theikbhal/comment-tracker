import SwiftUI
import AppKit

struct YearView: View {
    @EnvironmentObject var store: Store
    @State private var confirmReset = false
    @State private var message = ""

    private var filledCount: Int {
        store.yearCards.filter { !$0.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                    spacing: 12
                ) {
                    ForEach(store.yearCards) { card in
                        YearCardCell(card: card)
                    }
                }
                .padding(16)
            }
        }
        .confirmationDialog("Reset your year cards?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset — clear all 12", role: .destructive) {
                store.resetYearCards()
                message = "Year cards cleared"
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears all 12 month cards back to empty.")
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Year")
                        .font(.title.bold())
                    Text("\(filledCount)/12 cards filled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Spacer()
                if !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Button {
                    confirmReset = true
                } label: {
                    Label("Reset", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.red)
                .help("Clear all 12 month cards")
            }
        }
        .padding(16)
    }
}

// MARK: - Cell (in-place editable)

struct YearCardCell: View {
    @EnvironmentObject var store: Store
    let card: YearCard

    @State private var text = ""
    @FocusState private var focused: Bool

    private var isEmpty: Bool {
        card.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(card.monthName.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(card.slot)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
            TextField(isEmpty ? "Word for this month" : "", text: $text)
                .textFieldStyle(.plain)
                .focused($focused)
                .font(isEmpty ? .callout.italic() : .headline)
                .foregroundStyle(isEmpty ? .tertiary : .primary)
                .onSubmit(commit)
                .onChange(of: focused) { _, new in
                    if !new { commit() }
                }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(minHeight: 96, alignment: .topLeading)
        .background(isEmpty ? Color.gray.opacity(0.04) : Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(focused ? Color.blue.opacity(0.5) : (isEmpty ? Color.gray.opacity(0.1) : Color.gray.opacity(0.16)), lineWidth: focused ? 1.5 : 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onAppear {
            text = card.word
        }
    }

    private func commit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed != card.word {
            store.updateYearCard(id: card.id, word: trimmed)
        }
    }
}
