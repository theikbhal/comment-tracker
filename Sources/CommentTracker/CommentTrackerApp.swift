import SwiftUI
import AppKit

extension Notification.Name {
    static let addComment = Notification.Name("addComment")
    static let toggleSession = Notification.Name("toggleSession")
}

@main
struct CommentTrackerApp: App {
    @StateObject private var store = Store.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 860, minHeight: 560)
        }
        .defaultSize(width: 980, height: 660)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Comment…") {
                    NotificationCenter.default.post(name: .addComment, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                Button(store.activeSession == nil ? "Start Session" : "End Session") {
                    NotificationCenter.default.post(name: .toggleSession, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }
}
