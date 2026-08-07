import SwiftUI
import AppKit

struct SlackView: View {
    @EnvironmentObject var store: Store
    @State private var selectedChannelID: Int?
    @State private var draft = ""
    @State private var showingNewChannel = false
    @State private var newChannelName = ""
    @State private var newChannelColor = "blue"
    @State private var renamingChannel: SlackChannel?
    @State private var renameText = ""

    private var selectedChannel: SlackChannel? {
        guard let id = selectedChannelID else { return nil }
        return store.slackChannels.first { $0.id == id }
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            if let channel = selectedChannel {
                channelView(channel)
            } else {
                emptyState
            }
        }
        .sheet(isPresented: $showingNewChannel) {
            newChannelSheet
        }
        .sheet(item: $renamingChannel) { channel in
            VStack(alignment: .leading, spacing: 12) {
                Text("Rename channel")
                    .font(.headline)
                TextField("Channel name", text: $renameText)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Spacer()
                    Button("Cancel") { renamingChannel = nil }
                        .keyboardShortcut(.cancelAction)
                    Button("Save") {
                        store.renameSlackChannel(id: channel.id, name: renameText)
                        renamingChannel = nil
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(16)
            .frame(width: 360, height: 150)
        }
        .onAppear {
            if selectedChannelID == nil {
                selectedChannelID = store.slackChannels.first?.id
            }
        }
    }

    private var newChannelSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New channel")
                .font(.headline)
            TextField("e.g. random, bugs, ideas", text: $newChannelName)
                .textFieldStyle(.roundedBorder)
            HStack(spacing: 6) {
                ForEach(mindMapColorNames, id: \.self) { colorName in
                    Button {
                        newChannelColor = colorName
                    } label: {
                        Circle()
                            .fill(mindMapColor(colorName))
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: newChannelColor == colorName ? 2 : 0))
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                Spacer()
                Button("Cancel") { showingNewChannel = false }
                    .keyboardShortcut(.cancelAction)
                Button("Create") {
                    store.addSlackChannel(name: newChannelName, color: newChannelColor)
                    if let id = store.slackChannels.first(where: { $0.name == newChannelName.trimmingCharacters(in: .whitespacesAndNewlines) })?.id {
                        selectedChannelID = id
                    }
                    showingNewChannel = false
                    newChannelName = ""
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(newChannelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 360, height: 190)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("Channels")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showingNewChannel = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
                .help("New channel")
            }
            .padding(12)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(store.slackChannels) { channel in
                        channelRow(channel)
                    }
                }
                .padding(6)
            }
        }
        .frame(width: 210)
        .background(.background.secondary)
    }

    private func channelRow(_ channel: SlackChannel) -> some View {
        let isSelected = channel.id == selectedChannelID
        let color = mindMapColor(channel.color)
        let count = store.messages(in: channel.id).count
        return HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(channel.displayName)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .lineLimit(1)
            Spacer()
            Text("\(count)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear, in: RoundedRectangle(cornerRadius: 7))
        .contentShape(RoundedRectangle(cornerRadius: 7))
        .onTapGesture {
            selectedChannelID = channel.id
        }
        .contextMenu {
            Button {
                renameText = channel.name
                renamingChannel = channel
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            Button(role: .destructive) {
                store.deleteSlackChannel(channel.id)
                if selectedChannelID == channel.id {
                    selectedChannelID = store.slackChannels.first?.id
                }
            } label: {
                Label("Delete channel", systemImage: "trash")
            }
        }
    }

    private func channelView(_ channel: SlackChannel) -> some View {
        let messages = store.messages(in: channel.id)
        return VStack(spacing: 0) {
            HStack(spacing: 8) {
                Circle()
                    .fill(mindMapColor(channel.color))
                    .frame(width: 10, height: 10)
                Text(channel.displayName)
                    .font(.headline)
                Spacer()
                Text("\(messages.count) messages")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(14)
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if messages.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "bubble.left")
                                    .font(.system(size: 30))
                                    .foregroundStyle(.tertiary)
                                Text("No messages yet — say hi")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }
                        ForEach(messages) { message in
                            SlackMessageBubbleView(message: message, channelColor: mindMapColor(channel.color))
                        }
                    }
                    .padding(16)
                    .id("slackBottom")
                }
                .onAppear {
                    proxy.scrollTo("slackBottom", anchor: .bottom)
                }
                .onChange(of: messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo("slackBottom", anchor: .bottom)
                    }
                }
            }
            Divider()
            composer
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Message \(selectedChannel?.displayName ?? "#channel")", text: $draft)
                .textFieldStyle(.plain)
                .onSubmit { send() }
            Button {
                send()
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary : Color.accentColor)
            }
            .buttonStyle(.plain)
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .help("Send (Return)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func send() {
        guard let channel = selectedChannel else { return }
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.sendSlackMessage(channelID: channel.id, text: trimmed)
        draft = ""
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text("Pick a channel or create one")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SlackMessageBubbleView: View {
    @EnvironmentObject var store: Store
    let message: SlackMessage
    let channelColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(String(message.author.prefix(1)).uppercased())
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(channelColor.gradient, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(message.author)
                        .font(.caption.weight(.bold))
                    Text(message.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Text(message.text)
                    .font(.body)
                    .textSelection(.enabled)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.12), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .contextMenu {
            Button(role: .destructive) {
                store.deleteSlackMessage(message.id)
            } label: {
                Label("Delete message", systemImage: "trash")
            }
        }
    }
}
