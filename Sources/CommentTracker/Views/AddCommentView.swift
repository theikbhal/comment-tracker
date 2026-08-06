import SwiftUI

struct AddCommentView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var platform: Platform = .x
    @State private var bodyText = ""
    @State private var urlText = ""
    @State private var keepOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            platformPicker

            Divider()

            noteField

            urlField

            Divider()

            footer
        }
        .padding(24)
        .frame(width: 520)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Add Comment")
                    .font(.title2.bold())
                Text("Count a comment you posted")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if store.activeSession != nil {
                Label("session live", systemImage: "record.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.red.opacity(0.12), in: Capsule())
            }
        }
    }

    private var platformPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Where did you post?")
                .font(.headline)
            HStack(spacing: 10) {
                ForEach(Platform.allCases) { p in
                    platformButton(p)
                }
            }
        }
    }

    private func platformButton(_ p: Platform) -> some View {
        let selected = platform == p
        let isFocus = p == .x
        return Button {
            platform = p
        } label: {
            VStack(spacing: 6) {
                Image(systemName: p.symbol)
                    .font(.system(size: 24, weight: .semibold))
                Text(p.displayName)
                    .font(.subheadline.weight(.semibold))
                Text(p.handle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    if isFocus {
                        Image(systemName: "scope")
                            .font(.system(size: 9, weight: .bold))
                    }
                    Text(p.tier.uppercased())
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(selected ? p.color : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? p.color.opacity(0.14) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? p.color : Color.gray.opacity(0.18), lineWidth: selected ? 2.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("What did you comment?", systemImage: "text.bubble")
                .font(.headline)
            TextEditor(text: $bodyText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(bodyText.isEmpty ? Color.gray.opacity(0.3) : Color.gray.opacity(0.5), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if bodyText.isEmpty {
                        Text("e.g. Great point — here's my take on that…")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }
                .frame(minHeight: 90)
            Text("\(bodyText.count) characters")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var urlField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Link to your comment (optional)", systemImage: "link")
                .font(.headline)
            TextField("https://x.com/yourpost/status/1234", text: $urlText)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .controlSize(.large)
        }
    }

    private var footer: some View {
        HStack {
            Toggle(isOn: $keepOpen) {
                Text("Keep open for next")
                    .font(.caption)
            }
            .toggleStyle(.checkbox)
            Spacer()
            Button("Cancel") { dismiss() }
                .buttonStyle(.bordered)
            Button {
                store.addComment(platform: platform, body: bodyText, url: urlText)
                bodyText = ""
                urlText = ""
                if !keepOpen {
                    dismiss()
                }
            } label: {
                Label("Save Comment", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
    }
}
