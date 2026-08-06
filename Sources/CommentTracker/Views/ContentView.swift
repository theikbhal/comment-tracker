import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case today, people, history, help
    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .people: return "People"
        case .history: return "History"
        case .help: return "Help"
        }
    }

    var symbol: String {
        switch self {
        case .today: return "target"
        case .people: return "person.2"
        case .history: return "chart.bar.xaxis"
        case .help: return "questionmark.circle"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: Store
    @State private var selection: SidebarItem = .today
    @State private var showingAdd = false
    @State private var showingOnboarding = false

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.title, systemImage: item.symbol)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190)
            .safeAreaInset(edge: .bottom) {
                if selection == .today {
                    miniProgress
                }
            }
        } detail: {
            detail(for: selection)
        }
        .navigationTitle("Comment Tracker")
        .sheet(isPresented: $showingAdd) {
            AddCommentView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView()
                .environmentObject(store)
        }
        .onAppear {
            if !store.isOnboarded {
                showingOnboarding = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .addComment)) { _ in
            showingAdd = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSession)) { _ in
            store.toggleSession()
        }
    }

    @ViewBuilder
    private func detail(for item: SidebarItem) -> some View {
        switch item {
        case .today: TodayView()
        case .people: PeopleView()
        case .history: HistoryView()
        case .help: HelpView()
        }
    }

    private var miniProgress: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(store.todayCount)/\(store.subGoal)")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
            }
            ProgressView(value: store.subGoalProgress)
                .tint(.blue)
        }
        .padding(12)
        .background(.bar)
    }
}
